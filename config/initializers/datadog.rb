require 'datadog'

Datadog.configure do |c|
  # Enable the APM tracer
  c.tracing.enabled = true
  
  # Set service name
  c.service = 'zero-downtime'
  
  # Set environment (development, staging, production)
  c.env = Rails.env
  
  # Set version
  c.version = '1.0.0'
  
  # Configure tracing for Rails
  c.tracing.instrument :rails
  
  # Configure tracing for Active Record
  c.tracing.instrument :active_record
  
  # Configure tracing for Redis (if you use it)
  # c.tracing.instrument :redis
  
  # Configure tracing for Sidekiq (if you use it)
  # c.tracing.instrument :sidekiq
  
  # Configure tracing for HTTP requests
  c.tracing.instrument :http
  
  # Configure tracing for Net::HTTP
  c.tracing.instrument :net_http
  
  # Send traces to Datadog agent
  c.tracing.agent.host = ENV.fetch('DD_AGENT_HOST', '127.0.0.1')
  c.tracing.agent.port = ENV.fetch('DD_AGENT_PORT', 8126).to_i
end
