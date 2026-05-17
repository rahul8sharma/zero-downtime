# Trace Information Storage for PR Creation

## Overview

Incidents now store complete trace information from Datadog APM, making it easy to use this data when creating PRs to fix errors.

## New Fields Added

The following fields were added to the `incidents` table:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `trace_id` | string | Datadog trace ID (if available) | `6a0a057400000000114d364086dda5dc` |
| `span_id` | string | Datadog span ID (if available) | `2212137867420956680` |
| `trace_url` | string | Direct link to trace in Datadog | `https://app.datadoghq.eu/apm/trace/...` |
| `http_method` | string | HTTP request method | `GET`, `POST`, `PUT`, etc. |
| `http_path` | string | Request path | `/home/new`, `/api/v1/users` |
| `http_status` | integer | HTTP status code | `500`, `503`, etc. |
| `duration_ms` | float | Request duration in milliseconds | `6230.0`, `1542.5` |

## Migration

```ruby
rails db:migrate
# => Added 7 new columns to incidents table
```

## Usage in Rails Console

### Get incidents with full trace info:

```ruby
# Get recent errors
incidents = Incident.order(created_at: :desc).limit(10)

incidents.each do |inc|
  puts "Error: #{inc.title}"
  puts "  Path: #{inc.http_method} #{inc.http_path} -> #{inc.http_status}"
  puts "  Duration: #{inc.duration_ms}ms"
  puts "  Source: #{inc.source}"
  puts "  Trace URL: #{inc.trace_url}" if inc.trace_url
  puts ""
end
```

### Filter by HTTP method:

```ruby
# Get all POST errors
post_errors = Incident.where(http_method: 'POST')

# Get all errors for a specific path
path_errors = Incident.where(http_path: '/home/new')
```

### Get errors by controller/action:

```ruby
# Errors in HomeController#new
home_errors = Incident.where(source: 'HomeController#new')

# All critical errors over 5 seconds
slow_critical = Incident.where(severity: 'critical')
                        .where('duration_ms > ?', 5000)
```

## Using for PR Creation

### Example: Creating a PR description from incident data

```ruby
incident = Incident.find(123)

pr_description = <<~DESC
  ## Fix: #{incident.title}
  
  **Error Details:**
  - Endpoint: `#{incident.http_method} #{incident.http_path}`
  - Status Code: #{incident.http_status}
  - Controller: #{incident.source}
  - Duration: #{incident.duration_ms}ms
  - Severity: #{incident.severity}
  
  **Error Message:**
  ```
  #{incident.error_message}
  ```
  
  #{incident.trace_url ? "**Datadog Trace:** #{incident.trace_url}" : ""}
  
  **Root Cause:**
  [Explain the root cause based on the error details]
  
  **Fix:**
  [Describe what was changed to fix the issue]
  
  **Testing:**
  - [ ] Verified fix locally
  - [ ] Added test case for error scenario
  - [ ] Checked similar code paths
DESC

puts pr_description
```

### Example: Group errors for batch fixing

```ruby
# Group errors by controller
errors_by_controller = Incident.where(status: 'open')
                               .group(:source)
                               .count
                               .sort_by { |_, count| -count }

puts "Errors by Controller:"
errors_by_controller.each do |controller, count|
  puts "  #{controller}: #{count} errors"
end

# Get details for top error
top_controller = errors_by_controller.first[0]
incidents = Incident.where(source: top_controller)

puts "\nDetails for #{top_controller}:"
incidents.each do |inc|
  puts "  - #{inc.http_method} #{inc.http_path} (#{inc.duration_ms}ms)"
end
```

## UI Display

The incidents page now shows a **"Request Details"** section for each incident with:
- HTTP Method
- Request Path
- HTTP Status Code
- Request Duration
- Link to Datadog trace (if available)

Visit: http://localhost:3000/dashboard/incidents

## API Access

If you need to access this data via API, here's example JSON:

```json
{
  "id": 1,
  "title": "GET /home/new - 500 Error in HomeController#new",
  "severity": "critical",
  "status": "open",
  "http_method": "GET",
  "http_path": "/home/new",
  "http_status": 500,
  "duration_ms": 6230.0,
  "source": "HomeController#new",
  "service": "zero-downtime",
  "trace_url": "https://app.datadoghq.eu/apm/trace/...",
  "error_message": "HTTP 500 error in HomeController#new\nPath: /home/new\n...",
  "created_at": "2026-05-17T18:44:32.123Z"
}
```

## Automated PR Creation Script

Here's a template for automated PR creation:

```ruby
# scripts/create_fix_pr.rb
incident_id = ARGV[0]
incident = Incident.find(incident_id)

# Generate branch name
branch_name = "fix/#{incident.source.parameterize}-#{incident.http_status}"

# Create branch
`git checkout -b #{branch_name}`

# Generate PR title
pr_title = "Fix #{incident.http_status} error in #{incident.source}"

# Generate PR body with all trace info
pr_body = <<~BODY
  Fixes incident ##{incident.id}
  
  **Error:** #{incident.title}
  **Endpoint:** `#{incident.http_method} #{incident.http_path}`
  **Duration:** #{incident.duration_ms}ms
  **Severity:** #{incident.severity}
  
  #{incident.trace_url ? "[View in Datadog](#{incident.trace_url})" : ""}
  
  ## Changes
  - [List your changes here]
  
  ## Testing
  - [ ] Reproduced the error locally
  - [ ] Applied fix and verified resolution
  - [ ] Added regression test
BODY

puts "Branch: #{branch_name}"
puts "Title: #{pr_title}"
puts "\nBody:\n#{pr_body}"

# Save to file for gh cli
File.write('/tmp/pr_body.md', pr_body)

# Create PR with gh CLI
# `gh pr create --title "#{pr_title}" --body-file /tmp/pr_body.md`
```

Usage:
```bash
rails runner scripts/create_fix_pr.rb 123
```

## Database Schema

```sql
ALTER TABLE incidents ADD COLUMN trace_id VARCHAR;
ALTER TABLE incidents ADD COLUMN span_id VARCHAR;
ALTER TABLE incidents ADD COLUMN trace_url VARCHAR;
ALTER TABLE incidents ADD COLUMN http_method VARCHAR;
ALTER TABLE incidents ADD COLUMN http_path VARCHAR;
ALTER TABLE incidents ADD COLUMN http_status INTEGER;
ALTER TABLE incidents ADD COLUMN duration_ms REAL;
```

## Notes

- Trace IDs may not always be available from logs, but HTTP details are always captured
- Duration is in milliseconds for easier comparison
- HTTP status codes map to severity: 500 = critical, 501-503 = high, 504+ = medium
- Trace URLs include environment for direct access to the right Datadog instance

---

**All trace information is now automatically captured and stored when syncing from Datadog!**
