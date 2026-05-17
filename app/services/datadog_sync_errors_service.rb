class DatadogSyncErrorsService
  def initialize(project)
    @project = project
  end

  def perform
    return unless @project.datadog_api_key.present? && @project.datadog_app_key.present?

    fetch_and_store_errors
  end

  private

  def fetch_and_store_errors
    require 'net/http'
    require 'json'

    site = @project.datadog_site || 'datadoghq.com'

    # Use Logs API to search for HTTP 500 errors from APM traces
    # These show up as logs with the http.status_code tag
    uri = URI("https://api.#{site}/api/v2/logs/events/search")

    # Query for errors from the last 24 hours
    from_time = 24.hours.ago.iso8601
    to_time = Time.now.iso8601

    request_body = {
      filter: {
        # Search for logs from zero-downtime service with HTTP 500 status codes
        query: "service:zero-downtime @http.status_code:>=500",
        from: from_time,
        to: to_time
      },
      sort: "-timestamp",
      page: {
        limit: 100
      }
    }.to_json

    puts "=" * 80
    puts "LOGS API REQUEST (POST) - Searching for APM errors"
    puts "URL: #{uri}"
    puts "API KEY: #{@project.datadog_api_key[0..10]}..."
    puts "APP KEY: #{@project.datadog_app_key[0..10]}..."
    puts "Site: #{site}"
    puts "Request Body:"
    puts request_body
    puts "=" * 80

    request = Net::HTTP::Post.new(uri)
    request['DD-API-KEY'] = @project.datadog_api_key
    request['DD-APPLICATION-KEY'] = @project.datadog_app_key
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request.body = request_body

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.read_timeout = 30
      http.request(request)
    end

    puts "=" * 80
    puts "RESPONSE CODE: #{response.code}"
    puts "RESPONSE MESSAGE: #{response.message}"
    puts "RESPONSE BODY (first 1500 chars):"
    puts response.body[0..1500]
    puts "=" * 80

    if response.code == '200'
      data = JSON.parse(response.body)
      logs = data['data'] || []

      puts "Found #{logs.length} error logs"

      logs.each do |log|
        create_incident_from_apm_log(log)
      end

      Activity.log(
        action: 'datadog_sync_completed',
        project: @project,
        details: "Synced #{logs.length} errors from Datadog APM"
      )

      return { success: true, count: logs.length }
    else
      error_body = response.body
      error_parsed = JSON.parse(error_body) rescue { raw: error_body }

      puts "ERROR DETAILS:"
      puts error_parsed.inspect

      error_msg = if error_parsed.is_a?(Hash)
        error_parsed['errors']&.first || error_parsed['error'] || error_body[0..200]
      else
        error_body[0..200]
      end

      Activity.log(
        action: 'datadog_sync_failed',
        project: @project,
        details: "Failed to sync: #{response.code} - #{error_msg}"
      )

      return { success: false, error: "#{response.code} - #{error_msg}" }
    end
  rescue StandardError => e
    puts "EXCEPTION: #{e.class} - #{e.message}"
    puts e.backtrace.first(5).join("\n")

    Activity.log(
      action: 'datadog_sync_error',
      project: @project,
      details: "Error: #{e.message}"
    )

    return { success: false, error: e.message }
  end

  def create_incident_from_apm_log(log)
    attributes = log['attributes'] || {}
    log_id = log['id']

    # Check for existing incident by datadog_id first
    existing = Incident.find_by(datadog_id: log_id, project: @project)

    if existing
      existing.update(last_synced_at: Time.now)
      puts "⟳ Incident already exists (datadog_id: #{log_id}), updating last_synced_at"
      return
    end

    # Extract error details from APM log
    service = attributes['service'] || 'zero-downtime'
    inner_attrs = attributes['attributes'] || {}

    # Get HTTP information
    http_status = inner_attrs.dig('http', 'status_code')&.to_i || 500
    http_method = inner_attrs.dig('http', 'method') || 'GET'
    http_path = inner_attrs.dig('http', 'url_details', 'path') || '/'

    # Get controller/action information
    controller = inner_attrs['controller'] || 'UnknownController'
    action = inner_attrs['action'] || 'unknown'
    duration = inner_attrs['duration'] || 0
    duration_ms = (duration / 1000.0).round(2)  # Convert microseconds to milliseconds

    # Build error type from controller + action
    error_type = "#{controller}##{action}"

    # Check for duplicate based on error signature (same error type, path, status in last 24 hours)
    # This prevents creating multiple incidents for the same recurring error
    duplicate = Incident.find_duplicate(
      project: @project,
      source: error_type,
      http_path: http_path,
      http_status: http_status,
      within: 24.hours
    )

    if duplicate
      duplicate.update(last_synced_at: Time.now)
      puts "⟳ Duplicate incident detected (#{error_type} on #{http_path}), updating existing incident ##{duplicate.id}"
      return
    end

    # Get trace information from dd attributes
    dd_attrs = inner_attrs['dd'] || {}
    trace_id = dd_attrs['trace_id']
    span_id = dd_attrs['span_id']

    # Build Datadog trace URL if we have trace_id
    site = @project.datadog_site || 'datadoghq.eu'
    trace_url = if trace_id
                  "https://app.#{site}/apm/trace/#{trace_id}?env=#{dd_attrs['env'] || 'development'}"
                else
                  nil
                end

    # Get timestamp
    timestamp = attributes['timestamp'] || Time.now.iso8601

    # Build title
    title = "#{http_method} #{http_path} - #{http_status} Error in #{error_type}"

    # Build error message with more context
    error_msg = "HTTP #{http_status} error in #{error_type}\n" \
                "Path: #{http_path}\n" \
                "Method: #{http_method}\n" \
                "Duration: #{duration_ms}ms\n" \
                "Timestamp: #{timestamp}\n" \
                "#{trace_url ? 'Trace: ' + trace_url : ''}"

    # Stack trace (if available from tags or attributes)
    stack_trace = inner_attrs.dig('error', 'stack') || nil

    # Determine severity based on HTTP status code
    severity = case http_status
               when 500
                 'critical'  # Internal Server Error
               when 501..503
                 'high'
               when 504..599
                 'medium'
               else
                 'medium'
               end

    Incident.create!(
      project: @project,
      datadog_id: log_id,
      title: title.truncate(255),
      severity: severity,
      status: 'open',
      error_message: error_msg,
      stack_trace: stack_trace,
      service: service,
      source: error_type,
      # Trace information for PR creation
      trace_id: trace_id,
      span_id: span_id,
      trace_url: trace_url,
      http_method: http_method,
      http_path: http_path,
      http_status: http_status,
      duration_ms: duration_ms,
      last_synced_at: Time.now
    )

    puts "✓ Created incident: #{title[0..70]}"
  rescue => e
    puts "✗ Failed to create incident: #{e.message}"
    puts e.backtrace.first(3).join("\n")
    Rails.logger.error "Failed to create incident from log #{log_id}: #{e.message}"
  end

  def extract_tag_value(tags, key)
    tags.find { |t| t.start_with?("#{key}:") }&.split(':', 2)&.last
  end

  def create_incident_from_log(log)
    attributes = log['attributes'] || {}
    log_id = log['id']

    existing = Incident.find_by(datadog_id: log_id, project: @project)

    if existing
      existing.update(last_synced_at: Time.now)
      return
    end

    # Extract error details from log
    message = attributes['message'] || 'Unknown Error'
    status = attributes['status'] || 'error'
    service = attributes['service'] || 'unknown'

    # Try to extract stack trace from attributes
    stack_trace = attributes['error']&.dig('stack') ||
                  attributes['attributes']&.dig('error', 'stack') ||
                  message

    Incident.create!(
      project: @project,
      datadog_id: log_id,
      title: message.truncate(255),
      severity: map_severity_from_status(status),
      status: 'open',
      error_message: message,
      stack_trace: stack_trace,
      service: service,
      source: attributes['host'] || 'datadog-logs',
      last_synced_at: Time.now
    )

    puts "Created incident: #{message[0..50]}"
  rescue => e
    puts "Failed to create incident: #{e.message}"
    Rails.logger.error "Failed to create incident from log #{log_id}: #{e.message}"
  end

  def map_severity_from_status(status)
    case status&.downcase
    when 'critical', 'emerg', 'alert'
      'critical'
    when 'error', 'err'
      'high'
    when 'warning', 'warn'
      'medium'
    else
      'low'
    end
  end

  def process_errors(data)
    return unless data['data']

    data['data'].each do |log_entry|
      attributes = log_entry['attributes']
      next unless attributes

      # Use a unique identifier to avoid duplicates
      datadog_id = log_entry['id']

      # Check if we already have this error
      existing = Incident.find_by(datadog_id: datadog_id, project: @project)

      if existing
        # Update last_synced_at
        existing.update(last_synced_at: Time.now)
      else
        # Create new incident
        Incident.create(
          project: @project,
          datadog_id: datadog_id,
          title: extract_title(attributes),
          severity: map_severity(attributes['status']),
          status: 'open',
          error_message: attributes['message'],
          stack_trace: attributes['attributes']&.dig('error', 'stack'),
          service: attributes['service'],
          source: attributes['attributes']&.dig('error', 'source_file') || 'unknown',
          last_synced_at: Time.now
        )
      end
    end
  end

  def extract_title(attributes)
    message = attributes['message'] || 'Unknown Error'
    # Truncate to first 100 characters
    message.length > 100 ? "#{message[0..97]}..." : message
  end

  def map_severity(status)
    case status&.downcase
    when 'critical', 'emerg', 'alert'
      'critical'
    when 'error', 'err'
      'high'
    when 'warning', 'warn'
      'medium'
    else
      'low'
    end
  end
end
