# ✅ Trace Information Storage - Complete Implementation

## Summary

All Datadog trace information is now automatically captured and stored in the `incidents` table when syncing errors. This makes it easy to create PRs with full context about the error.

## What Was Added

### 1. Database Fields (Migration)

Added 7 new columns to store trace information:

```ruby
trace_id        # Datadog trace ID (if available)
span_id         # Datadog span ID (if available)  
trace_url       # Direct link to Datadog trace
http_method     # GET, POST, PUT, DELETE, etc.
http_path       # Request path like /home/new
http_status     # HTTP status code (500, 503, etc.)
duration_ms     # Request duration in milliseconds
```

Migration: `db/migrate/20260517184328_add_trace_info_to_incidents.rb`

### 2. Service Updates

**File:** `app/services/datadog_sync_errors_service.rb`

The sync service now extracts and stores:
- HTTP method, path, and status from log attributes
- Request duration (converted from microseconds to milliseconds)
- Trace ID and span ID from dd attributes (when available)
- Auto-generates Datadog trace URL for easy navigation

### 3. Model Helper Methods

**File:** `app/models/incident.rb`

Added convenient methods for PR creation:

```ruby
incident.pr_description          # Full markdown PR description
incident.suggested_branch_name   # e.g., "fix/homecontroller-new-500-error"
incident.suggested_pr_title      # e.g., "Fix 500 error in HomeController#new"
incident.trace_summary          # Hash with all trace info
```

### 4. Enhanced UI

**File:** `app/views/dashboard/incidents.html.erb`

The incidents page now displays a **"Request Details"** card showing:
- HTTP Method (GET, POST, etc.)
- Request Path
- HTTP Status Code (in red for errors)
- Request Duration in milliseconds
- Link to Datadog trace (if available)

### 5. PR Creation Script

**File:** `scripts/create_fix_pr.rb`

Automated script to create fix branches and PR descriptions:

```bash
rails runner scripts/create_fix_pr.rb 35
```

## Usage Examples

### View Trace Information

```ruby
incident = Incident.find(35)

# Get trace summary
puts incident.trace_summary.to_json
# => {"endpoint":"GET /home/new","status":500,"duration":"5480.0ms",...}

# Get PR description
puts incident.pr_description
# => Full markdown with error details, trace link, checklist
```

### Filter by Trace Data

```ruby
# All GET requests with errors
Incident.where(http_method: 'GET')

# Errors on specific path
Incident.where(http_path: '/home/new')

# Slow errors (> 5 seconds)
Incident.where('duration_ms > ?', 5000)

# Critical 500 errors
Incident.critical.where(http_status: 500)
```

### Create a PR

**Option 1: Using the script**
```bash
rails runner scripts/create_fix_pr.rb 35
# Follow the prompts to create branch and PR description
```

**Option 2: Manual**
```ruby
incident = Incident.find(35)

# Create branch
branch = incident.suggested_branch_name
`git checkout -b #{branch}`

# Get PR details
title = incident.suggested_pr_title
body = incident.pr_description

# Save for gh CLI
File.write('/tmp/pr.md', body)

# Create PR with GitHub CLI
`gh pr create --title "#{title}" --body-file /tmp/pr.md`
```

### Group Errors for Batch Fixing

```ruby
# Group by controller
errors = Incident.open
                 .group(:source)
                 .count
                 .sort_by { |_, count| -count }

puts "Top errors by controller:"
errors.first(5).each do |controller, count|
  incidents = Incident.where(source: controller)
  avg_duration = incidents.average(:duration_ms)
  
  puts "#{controller}: #{count} errors"
  puts "  Average duration: #{avg_duration.round(2)}ms"
  puts "  Paths affected: #{incidents.pluck(:http_path).uniq.join(', ')}"
end
```

## Sample PR Description

When you call `incident.pr_description`, you get:

```markdown
## Fix: GET /home/new - 500 Error in HomeController#new

**Error Details:**
- Endpoint: `GET /home/new`
- HTTP Status: 500
- Controller/Action: HomeController#new
- Duration: 5480.0ms
- Severity: **CRITICAL**
- Service: zero-downtime

**Error Message:**
```
HTTP 500 error in HomeController#new
Path: /home/new
Method: GET
Duration: 5480.0ms
Timestamp: 2026-05-17T18:20:42.448Z
```

**Root Cause:**
[Analyze the error and describe the root cause here]

**Changes:**
- [ ] [List the changes made to fix this issue]

**Testing:**
- [ ] Reproduced the error locally
- [ ] Applied fix and verified resolution
- [ ] Added test case to prevent regression
- [ ] Tested similar code paths

---

Fixes incident #35 | First seen: 2026-05-17 18:44 UTC
```

## Viewing in UI

Visit: **http://localhost:3000/dashboard/incidents**

Each incident now shows:
- 🔍 **Request Details** section with:
  - HTTP method and path
  - Status code (highlighted in red)
  - Request duration
  - Link to Datadog trace

## Quick Reference

| Task | Command |
|------|---------|
| Sync errors | Click "🔄 Sync Datadog Errors" button |
| View incidents | http://localhost:3000/dashboard/incidents |
| Get trace info | `Incident.find(id).trace_summary` |
| Create PR | `rails runner scripts/create_fix_pr.rb <id>` |
| List available | `rails runner scripts/create_fix_pr.rb` |

## Example Workflow

1. **Sync errors from Datadog:**
   - Go to incidents page
   - Click "🔄 Sync Datadog Errors"
   - See new incidents with full trace info

2. **Review the error:**
   - Click on incident to see details
   - Note the HTTP method, path, status
   - Check duration to see if it's performance-related
   - Click "View in Datadog" for full trace

3. **Create a PR:**
   ```bash
   rails runner scripts/create_fix_pr.rb 35
   # Follow prompts
   # Make your fixes
   # Commit and push
   # Create PR with provided description
   ```

4. **All trace info is included automatically!**

## Database Schema

```sql
-- New columns added
ALTER TABLE incidents ADD COLUMN trace_id VARCHAR;
ALTER TABLE incidents ADD COLUMN span_id VARCHAR;
ALTER TABLE incidents ADD COLUMN trace_url VARCHAR;
ALTER TABLE incidents ADD COLUMN http_method VARCHAR;
ALTER TABLE incidents ADD COLUMN http_path VARCHAR;
ALTER TABLE incidents ADD COLUMN http_status INTEGER;
ALTER TABLE incidents ADD COLUMN duration_ms REAL;
```

## Files Changed

1. ✅ `db/migrate/20260517184328_add_trace_info_to_incidents.rb` - Migration
2. ✅ `app/services/datadog_sync_errors_service.rb` - Extract & store trace data
3. ✅ `app/models/incident.rb` - Helper methods for PR creation
4. ✅ `app/views/dashboard/incidents.html.erb` - Display trace info in UI
5. ✅ `scripts/create_fix_pr.rb` - Automated PR creation script

## Documentation

- **[TRACE_INFO_FOR_PR.md](TRACE_INFO_FOR_PR.md)** - Complete guide with examples
- **This file** - Quick reference and implementation summary

---

**Status:** ✅ Complete! All trace information is now captured and ready for PR creation.
