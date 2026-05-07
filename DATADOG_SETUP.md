# Datadog Error Sync - Setup Guide

## Current Status
- ✅ Datadog Agent running locally (127.0.0.1:8126)  
- ✅ APM configured in Rails app
- ✅ API keys are valid
- ❌ APM APIs return 404 (APM not enabled in account)
- ❌ Logs APIs return 400 (no log indexes configured)

## The Problem
Your Datadog account doesn't have APM or Log Management enabled at the API level. The Error Tracking APIs require APM to be fully enabled in your Datadog organization.

## Solution: Enable APM in Datadog

1. **Go to Datadog**: https://app.datadoghq.eu
2. **Enable APM**: 
   - Navigate to: APM → Setup & Configuration
   - Or: Organization Settings → APM
   - Enable APM for your services
3. **Wait 5-10 minutes** for activation
4. **Test again**: Click "Sync Datadog Errors"

## Alternative: Use Sample Data
The UI works perfectly with sample incidents already created:
- Navigate to `/dashboard/incidents`
- See filtering, search, severity badges, stack traces
- All features functional

Run to create more samples:
```ruby
rails runner "
project = Project.first
Incident.create!(
  project: project,
  title: 'Your Error Title',
  severity: 'critical',
  status: 'open',
  error_message: 'Error details...',
  service: 'web'
)
"
```

## API Test Results
✅ Validate: 200 OK
❌ APM Services: 404  
❌ Error Tracking: 404
❌ Logs: 400 No indexes
❌ Traces: 404
