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

    # Datadog Error Tracking API endpoint
    site = @project.datadog_site || 'datadoghq.com'

    # Try APM traces endpoint instead of logs
    uri = URI("https://api.#{site}/api/v1/events")

    # Search for errors in the last 24 hours using epoch seconds
    from_time = 24.hours.ago.to_i
    to_time = Time.now.to_i

    # Build query parameters for events API
    query_params = {
      start: from_time,
      end: to_time,
      priority: "normal",
      sources: "nagios,chef,my_app",
      tags: "error,exception"
    }

    uri.query = URI.encode_www_form(query_params)

    puts "=" * 80
    puts "REQUEST URL: #{uri}"
    puts "API KEY: #{@project.datadog_api_key[0..10]}..."
    puts "APP KEY: #{@project.datadog_app_key[0..10]}..."
    puts "=" * 80

    request = Net::HTTP::Get.new(uri)
    request['DD-API-KEY'] = @project.datadog_api_key
    request['DD-APPLICATION-KEY'] = @project.datadog_app_key
    request['Accept'] = 'application/json'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    puts "=" * 80
    puts "RESPONSE CODE: #{response.code}"
    puts "RESPONSE MESSAGE: #{response.message}"
    puts "RESPONSE BODY: #{response.body[0..500]}"
    puts "=" * 80

    if response.code == '200'
      data = JSON.parse(response.body)

      # For events API, the structure is different
      events = data['events'] || []

      events.each do |event|
        create_incident_from_event(event)
      end

      Activity.log(
        action: 'datadog_sync_completed',
        project: @project,
        details: "Synced #{events.length} errors from Datadog"
      )

      return { success: true, count: events.length }
    else
      # Log the full response body for debugging
      error_response = JSON.parse(response.body) rescue response.body

      Activity.log(
        action: 'datadog_sync_failed',
        project: @project,
        details: "Failed to sync errors: #{response.code} - #{error_response}"
      )

      return { success: false, error: "#{response.code} - #{error_response}" }
    end
  rescue StandardError => e
    Activity.log(
      action: 'datadog_sync_error',
      project: @project,
      details: "Error syncing Datadog: #{e.message}"
    )

    return { success: false, error: e.message }
  end

  def create_incident_from_event(event)
    # Check if we already have this error
    datadog_id = event['id']&.to_s || "event-#{event['date_happened']}"

    existing = Incident.find_by(datadog_id: datadog_id, project: @project)
    return if existing

    # Create new incident from event
    Incident.create(
      project: @project,
      datadog_id: datadog_id,
      title: event['title'] || 'Unknown Error',
      severity: map_priority(event['priority']),
      status: 'open',
      error_message: event['text'],
      stack_trace: event['text'],
      service: event['tags']&.first || 'unknown',
      source: event['source'] || 'datadog',
      last_synced_at: Time.now
    )
  end

  def map_priority(priority)
    case priority&.downcase
    when 'critical', 'urgent'
      'critical'
    when 'high', 'error'
      'high'
    when 'normal', 'warning'
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
