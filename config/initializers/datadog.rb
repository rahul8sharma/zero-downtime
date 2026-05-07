require 'datadog'

Datadog.configure do |c|
  # Set service name
  c.service = 'zero-downtime'

  # Set environment (development, staging, production)
  c.env = Rails.env

  # Set version
  c.version = '1.0.0'

  # Configure tracing for Rails (includes ActionController, ActionView, ActiveRecord)
  c.tracing.instrument :rails

  # Configure tracing for HTTP requests (Net::HTTP is included)
  c.tracing.instrument :http

  # Enable error tracking
  c.tracing.report_hostname = true

  # Agent configuration is done via environment variables:
  # DD_AGENT_HOST (defaults to 127.0.0.1)
  # DD_TRACE_AGENT_PORT (defaults to 8126)
end

# Configure error tracking
Rails.application.config.middleware.use(
  Datadog::Tracing::Contrib::Rails::ExceptionMiddleware
)


# Datadog.configure do |c|
#   c.env = 'development'
#   c.service = 'zero-downtime'
#   c.tracing.sampling.default_rate = 1.0
#   c.profiling.enabled = true
#   c.appsec.enabled = true
#   c.appsec.sca.enabled = true
# end
