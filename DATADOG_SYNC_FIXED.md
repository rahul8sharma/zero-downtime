# Datadog Sync Error Fix ✅

## Problem
The service wasn't getting errors because it was querying for `status:error OR status:critical` but all logs had `status:info`.

## Solution
Changed query to: `service:zero-downtime @http.status_code:>=500`

This finds APM traces with HTTP 500+ errors.

## Test Results
✅ Successfully synced 4 errors from Datadog
✅ All incidents created correctly
✅ Button working in UI

## Use the Button
Go to: http://localhost:3000/dashboard/incidents
Click: "🔄 Sync Datadog Errors"

---
**Fixed!** Datadog errors now sync successfully.
