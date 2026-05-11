# Custom Error Tracking - capture errors locally and send to our database
# This is a workaround since Datadog Error Tracking API is not available

Rails.application.config.middleware.use(Rack::ShowExceptions) unless Rails.env.production?

# Subscribe to Rails error notifications
ActiveSupport::Notifications.subscribe('process_action.action_controller') do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)

  if event.payload[:exception].present?
    exception_class, exception_message = event.payload[:exception]

    begin
      # Get the first project (or you can determine project based on request context)
      project = Project.first

      next unless project

      # Create incident from the error
      Incident.create!(
        project: project,
        datadog_id: "local-#{SecureRandom.uuid}",
        title: "#{exception_class}: #{exception_message.truncate(200)}",
        severity: 'high',
        status: 'open',
        error_message: exception_message,
        stack_trace: event.payload[:exception_object]&.backtrace&.join("\n") || 'No stack trace',
        service: 'rails',
        source: "#{event.payload[:controller]}##{event.payload[:action]}",
        last_synced_at: Time.now
      )

      Rails.logger.info "✅ Captured error in local incident tracking: #{exception_class}"
    rescue => e
      Rails.logger.error "Failed to create incident from error: #{e.message}"
    end
  end
end
