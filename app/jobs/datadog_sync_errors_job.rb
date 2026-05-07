class DatadogSyncErrorsJob < ApplicationJob
  queue_as :default

  def perform(project_id)
    project = Project.find(project_id)

    return unless project.datadog_api_key.present? && project.datadog_app_key.present?

    fetch_and_store_errors(project)
  end

  private

  def fetch_and_store_errors(project)
    require 'net/http'
    require 'json'

    # Datadog Error Tracking API endpoint
    site = project.datadog_site || 'datadoghq.com'
    uri = URI("https://api.#{site}/api/v2/logs/events/search")

    # Search for errors in the last 24 hours
    from_time = (24.hours.ago.to_f * 1000).to_i
    to_time = (Time.now.to_f * 1000).to_i

    request_body = {
      filter: {
        from: from_time.to_s,
        to: to_time.to_s,
        query: "status:(error OR critical)"
      },
      sort: "-timestamp",
      page: {
        limit: 100
      }
    }

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['DD-API-KEY'] = project.datadog_api_key
    request['DD-APPLICATION-KEY'] = project.datadog_app_key
    request.body = request_body.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code == '200'
      data = JSON.parse(response.body)
      process_errors(data, project)

      Activity.log(
        action: 'datadog_sync_completed',
        project: project,
        details: "Synced #{data['data']&.length || 0} errors from Datadog"
      )
    else
      # Log the full response body for debugging
      error_body = response.body.present? ? response.body[0..200] : 'No response body'
      Activity.log(
        action: 'datadog_sync_failed',
        project: project,
        details: "Failed to sync errors: #{response.code} - #{response.message}. Response: #{error_body}"
      )
      Rails.logger.error "Datadog sync failed for project #{project.id}: #{response.code} - #{response.body}"
    end
  rescue StandardError => e
    Activity.log(
      action: 'datadog_sync_error',
      project: project,
      details: "Error syncing Datadog: #{e.message}"
    )
    Rails.logger.error "Datadog sync error for project #{project.id}: #{e.message}\n#{e.backtrace.join("\n")}"
  end

  def process_errors(data, project)
    return unless data['data']

    data['data'].each do |log_entry|
      attributes = log_entry['attributes']
      next unless attributes

      # Use a unique identifier to avoid duplicates
      datadog_id = log_entry['id']

      # Check if we already have this error
      existing = Incident.find_by(datadog_id: datadog_id, project: project)

      if existing
        # Update last_synced_at
        existing.update(last_synced_at: Time.now)
      else
        # Create new incident
        Incident.create(
          project: project,
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
