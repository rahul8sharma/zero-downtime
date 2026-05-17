require 'datadog'

Datadog.configure do |c|
  # Set service name
  c.service = 'zero-downtime'

  # Set environment (development, staging, production)
  c.env = Rails.env

  # Set version
  c.version = '1.0.0'

  # Enable runtime metrics for better monitoring
  c.runtime_metrics.enabled = true

  # Configure tracing for Rails (includes ActionController, ActionView, ActiveRecord)
  c.tracing.instrument :rails, service_name: 'zero-downtime'

  # Configure tracing for HTTP requests (Net::HTTP is included)
  c.tracing.instrument :http, service_name: 'zero-downtime-http'

  # Configure trace sampling (1.0 = 100% for development)
  c.tracing.sampling.default_rate = Rails.env.production? ? 0.1 : 1.0

  # Agent configuration is done via environment variables:
  # DD_AGENT_HOST (defaults to 127.0.0.1)
  # DD_TRACE_AGENT_PORT (defaults to 8126)
  # DD_API_KEY and DD_APP_KEY from config/application.yml
end


# Datadog.configure do |c|
#   c.env = 'development'
#   c.service = 'zero-downtime'
#   c.tracing.sampling.default_rate = 1.0
#   c.profiling.enabled = true
#   c.appsec.enabled = true
#   c.appsec.sca.enabled = true
# end
