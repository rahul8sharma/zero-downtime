# Datadog Integration Setup

## Prerequisites

1. **Datadog Agent Installed Locally**
   - You mentioned you already have this ✓

2. **Datadog API Key**
   - Get it from: https://app.datadoghq.com/organization-settings/api-keys

## Configuration Steps

### Step 1: Add Your API Key

Edit `config/application.yml` and replace:
```yaml
DD_API_KEY: your_datadog_api_key_here
```

With your actual API key:
```yaml
DD_API_KEY: abc123def456...
```

### Step 2: Verify Datadog Agent is Running

Check if the Datadog agent is running on your machine:

```bash
# Check if agent is running
ps aux | grep datadog-agent

# Check agent status (macOS)
datadog-agent status

# If not running, start it:
sudo launchctl start com.datadoghq.agent
```

### Step 3: Restart Your Rails Server

```bash
pkill -f "rails server"
rails server
```

## What Gets Tracked

Once configured, Datadog will automatically track:

✅ **Application Performance (APM)**
- Request traces
- Response times
- Error rates
- Throughput

✅ **Database Queries**
- SQL queries
- Query duration
- Active Record operations

✅ **HTTP Requests**
- External API calls
- Response times
- Status codes

✅ **Custom Metrics**
- You can add custom tracking

## Verify Integration

1. **Restart Rails Server**
2. **Make Some Requests** to your app (visit pages, create projects, etc.)
3. **Check Datadog Dashboard**
   - Go to https://app.datadoghq.com/apm/traces
   - You should see traces from `zero-downtime` service

## Troubleshooting

### Traces Not Appearing?

1. **Check Agent Status:**
   ```bash
   datadog-agent status
   ```

2. **Check Rails Logs:**
   Look for Datadog initialization messages when server starts

3. **Check Agent Host/Port:**
   - Default: `127.0.0.1:8126`
   - Verify in `config/initializers/datadog.rb`

4. **Verify API Key:**
   - Make sure it's correct in `config/application.yml`

### Need Help?

- Datadog Docs: https://docs.datadoghq.com/tracing/trace_collection/dd_libraries/ruby/
- Check agent logs: `/var/log/datadog/agent.log` (macOS)

## Custom Metrics Example

To send custom metrics to Datadog:

```ruby
require 'datadog/statsd'

# In your code
statsd = Datadog::Statsd.new('localhost', 8125)

# Increment counter
statsd.increment('github.connections')

# Time an operation
statsd.time('project.creation') do
  Project.create!(name: 'Test')
end

# Send a gauge
statsd.gauge('projects.total', Project.count)
```

## Environment Variables

You can also set these via environment variables instead of `application.yml`:

```bash
export DD_API_KEY=your_api_key
export DD_AGENT_HOST=127.0.0.1
export DD_AGENT_PORT=8126
export DD_ENV=development
export DD_SERVICE=zero-downtime
```
