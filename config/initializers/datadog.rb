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

  # Agent configuration is done via environment variables:
  # DD_AGENT_HOST (defaults to 127.0.0.1)
  # DD_TRACE_AGENT_PORT (defaults to 8126)
end
