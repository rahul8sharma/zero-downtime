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

    # Use Error Tracking Issues API - this is what powers the Errors tab
    uri = URI("https://api.#{site}/api/v2/apm/issues")

    # Query for issues from the last 7 days
    from_time = (7.days.ago.to_f * 1000).to_i
    to_time = (Time.now.to_f * 1000).to_i

    query_params = {
      'filter[from]': from_time,
      'filter[to]': to_time,
      'page[limit]': 100
    }

    uri.query = URI.encode_www_form(query_params)

    puts "=" * 80
    puts "ERROR TRACKING API REQUEST"
    puts "URL: #{uri}"
    puts "API KEY: #{@project.datadog_api_key[0..10]}..."
    puts "APP KEY: #{@project.datadog_app_key[0..10]}..."
    puts "Service: #{@project.datadog_site}"
    puts "=" * 80

    request = Net::HTTP::Get.new(uri)
    request['DD-API-KEY'] = @project.datadog_api_key
    request['DD-APPLICATION-KEY'] = @project.datadog_app_key
    request['Accept'] = 'application/json'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.read_timeout = 30
      http.request(request)
    end

    puts "=" * 80
    puts "RESPONSE CODE: #{response.code}"
    puts "RESPONSE MESSAGE: #{response.message}"
    puts "RESPONSE HEADERS: #{response.to_hash.inspect}"
    puts "RESPONSE BODY (first 1000 chars):"
    puts response.body[0..1000]
    puts "=" * 80

    if response.code == '200'
      data = JSON.parse(response.body)
      issues = data['data'] || []

      puts "Found #{issues.length} error issues"

      issues.each do |issue|
        create_incident_from_issue(issue)
      end

      Activity.log(
        action: 'datadog_sync_completed',
        project: @project,
        details: "Synced #{issues.length} errors from Datadog Error Tracking"
      )

      return { success: true, count: issues.length }
    else
      error_body = response.body
      error_parsed = JSON.parse(error_body) rescue { raw: error_body }

      puts "ERROR DETAILS:"
      puts error_parsed.inspect

      Activity.log(
        action: 'datadog_sync_failed',
        project: @project,
        details: "Failed to sync: #{response.code} - #{error_parsed['errors']&.first || error_body[0..200]}"
      )

      return { success: false, error: "#{response.code} - #{error_parsed['errors']&.first&.dig('detail') || error_body[0..200]}" }
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

  def create_incident_from_issue(issue)
    attributes = issue['attributes'] || {}
    issue_id = issue['id']

    existing = Incident.find_by(datadog_id: issue_id, project: @project)

    if existing
      existing.update(last_synced_at: Time.now)
      return
    end

    # Extract error details
    title = attributes['title'] || 'Unknown Error'
    message = attributes['message'] || attributes['title'] || ''
    stack_trace = attributes['stack_trace'] || ''

    Incident.create!(
      project: @project,
      datadog_id: issue_id,
      title: title.truncate(255),
      severity: map_severity_from_issue(attributes),
      status: 'open',
      error_message: message,
      stack_trace: stack_trace,
      service: attributes['service'] || 'unknown',
      source: attributes['resource'] || 'datadog-apm',
      last_synced_at: Time.now
    )

    puts "Created incident: #{title[0..50]}"
  rescue => e
    puts "Failed to create incident: #{e.message}"
    Rails.logger.error "Failed to create incident from issue #{issue_id}: #{e.message}"
  end

  def map_severity_from_issue(attributes)
    # APM issues don't have severity, use impact or error count
    impact = attributes['impact']
    error_count = attributes['error_count'] || 0

    if error_count > 100
      'critical'
    elsif error_count > 10
      'high'
    else
      'medium'
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
