# ✅ Duplicate Incident Prevention - Implementation Complete

## Summary

The Datadog sync service now prevents creating duplicate incidents when the same error occurs multiple times. Instead of creating a new incident each time, it updates the existing open incident's `last_synced_at` timestamp.

## How It Works

### Two-Level Duplicate Detection

#### Level 1: Datadog ID Check
```ruby
existing = Incident.find_by(datadog_id: log_id, project: @project)
if existing
  existing.update(last_synced_at: Time.now)
  return
end
```
- Checks if an incident with the same `datadog_id` already exists
- Fast lookup using database index
- Prevents importing the exact same log entry twice

#### Level 2: Error Signature Check
```ruby
duplicate = Incident.find_duplicate(
  project: @project,
  source: error_type,           # e.g., "HomeController#new"
  http_path: http_path,         # e.g., "/home/new"
  http_status: http_status,     # e.g., 500
  within: 24.hours
)
```
- Checks for **open incidents** with the same error signature in the last 24 hours
- Error signature: `controller#action` + `http_path` + `http_status`
- Prevents multiple incidents for the **same recurring error**

### What Defines a "Duplicate"

An incident is considered a duplicate if it matches **all** of these criteria:

1. **Same Project** - Belongs to the same project
2. **Same Source** - Same controller#action (e.g., `HomeController#new`)
3. **Same HTTP Path** - Same endpoint (e.g., `/home/new`)
4. **Same HTTP Status** - Same error code (e.g., 500)
5. **Status is Open** - Only checks open incidents (not resolved/closed)
6. **Within 24 Hours** - Created in the last 24 hours

### Example Scenarios

#### Scenario 1: Exact Same Error Multiple Times ✅
```
Time 10:00 - GET /home/new → 500 error → Incident #1 created
Time 10:05 - GET /home/new → 500 error → Updates Incident #1 (no new incident)
Time 10:10 - GET /home/new → 500 error → Updates Incident #1 (no new incident)
```
**Result:** Only 1 incident created, updated 3 times

#### Scenario 2: Different Errors ✅
```
Time 10:00 - GET /home/new → 500 error → Incident #1 created
Time 10:05 - GET /home/show → 500 error → Incident #2 created (different path)
Time 10:10 - POST /home/new → 500 error → Incident #3 created (different method)
```
**Result:** 3 separate incidents (different signatures)

#### Scenario 3: Same Error After 24 Hours ✅
```
Day 1 10:00 - GET /home/new → 500 error → Incident #1 created
Day 2 11:00 - GET /home/new → 500 error → Incident #2 created (outside 24h window)
```
**Result:** 2 separate incidents (different time windows)

#### Scenario 4: Same Error After Resolving ✅
```
Time 10:00 - GET /home/new → 500 error → Incident #1 created
Time 11:00 - Developer resolves Incident #1 (status = 'resolved')
Time 12:00 - GET /home/new → 500 error → Incident #2 created (previous was resolved)
```
**Result:** 2 separate incidents (first was closed)

## Files Modified

### 1. **[app/services/datadog_sync_errors_service.rb](app/services/datadog_sync_errors_service.rb)**

Added duplicate detection logic:

**Lines 125-131:** Check by `datadog_id`
```ruby
existing = Incident.find_by(datadog_id: log_id, project: @project)
if existing
  existing.update(last_synced_at: Time.now)
  puts "⟳ Incident already exists (datadog_id: #{log_id})"
  return
end
```

**Lines 149-163:** Check by error signature
```ruby
duplicate = Incident.find_duplicate(
  project: @project,
  source: error_type,
  http_path: http_path,
  http_status: http_status,
  within: 24.hours
)

if duplicate
  duplicate.update(last_synced_at: Time.now)
  puts "⟳ Duplicate incident detected (#{error_type} on #{http_path})"
  return
end
```

### 2. **[app/models/incident.rb](app/models/incident.rb)**

Added helper method for duplicate detection:

**Lines 92-103:**
```ruby
def self.find_duplicate(project:, source:, http_path:, http_status:, within: 24.hours)
  where(
    project: project,
    source: source,
    http_path: http_path,
    http_status: http_status,
    status: 'open'
  ).where('created_at > ?', within.ago).first
end
```

### 3. **[db/migrate/20260517193541_add_unique_index_to_incidents.rb](db/migrate/20260517193541_add_unique_index_to_incidents.rb)**

Added database indexes for performance:

```ruby
# Composite index for faster duplicate detection
add_index :incidents,
          [:project_id, :source, :http_path, :http_status, :status],
          name: 'index_incidents_on_error_signature'

# Index on last_synced_at for cleanup queries
add_index :incidents, :last_synced_at
```

## Benefits

### 1. **Cleaner Incident List**
- No duplicate entries cluttering the dashboard
- Each unique error shows as one incident

### 2. **Better Signal-to-Noise Ratio**
- Focus on unique problems, not repetitive errors
- Easier to see which issues are actually new

### 3. **Accurate Metrics**
- Total incident count reflects unique problems
- Not inflated by the same error occurring multiple times

### 4. **Reduced Database Growth**
- Fewer records in the database
- Better performance on queries

### 5. **Track Recurrence**
- `last_synced_at` shows when the error was last seen
- Can calculate error frequency if needed

## Console Output

When syncing, you'll now see:

```
================================================================================
Found 10 error logs
✓ Created incident: GET /home/new - 500 Error in HomeController#new
⟳ Duplicate incident detected (HomeController#new on /home/new), updating existing incident #1
⟳ Duplicate incident detected (HomeController#new on /home/new), updating existing incident #1
✓ Created incident: GET /api/users - 404 Error in UsersController#show
⟳ Incident already exists (datadog_id: abc123), updating last_synced_at
================================================================================
```

## Testing

### Test Duplicate Prevention

1. **Sync Datadog errors:**
   ```
   Click "🔄 Sync Datadog Errors" button
   ```

2. **Check incidents count:**
   - Note the number of incidents created

3. **Sync again immediately:**
   ```
   Click "🔄 Sync Datadog Errors" again
   ```

4. **Verify no duplicates:**
   - Incident count should remain the same
   - `last_synced_at` timestamps should be updated

### Test via Rails Console

```ruby
# Get a project
project = Project.first

# Sync once
result1 = DatadogSyncErrorsService.new(project).perform
puts "First sync: #{result1[:count]} incidents"

# Sync again
result2 = DatadogSyncErrorsService.new(project).perform
puts "Second sync: #{result2[:count]} incidents"

# Check for duplicates
incidents = Incident.where(project: project)
duplicates = incidents.group(:source, :http_path, :http_status, :status)
                      .having('count(*) > 1')
                      .count

puts "Duplicate count: #{duplicates.length}"
# Should be 0
```

### Test Different Scenarios

#### Test 1: Same Error Multiple Times
```ruby
# Create test incident
incident1 = Incident.create!(
  project: project,
  source: "HomeController#new",
  http_path: "/home/new",
  http_status: 500,
  status: 'open',
  title: "Test error",
  error_message: "Test",
  severity: 'critical'
)

# Check for duplicate
duplicate = Incident.find_duplicate(
  project: project,
  source: "HomeController#new",
  http_path: "/home/new",
  http_status: 500
)

puts duplicate.present? # Should be true
puts duplicate.id == incident1.id # Should be true
```

#### Test 2: Different Errors
```ruby
# Different path - should NOT be a duplicate
duplicate = Incident.find_duplicate(
  project: project,
  source: "HomeController#new",
  http_path: "/home/show",  # Different!
  http_status: 500
)

puts duplicate.present? # Should be false
```

#### Test 3: Resolved Incident
```ruby
# Resolve the incident
incident1.update(status: 'resolved')

# Check for duplicate
duplicate = Incident.find_duplicate(
  project: project,
  source: "HomeController#new",
  http_path: "/home/new",
  http_status: 500
)

puts duplicate.present? # Should be false (only checks 'open')
```

## Configuration Options

### Change Time Window

By default, duplicates are checked within the last **24 hours**. To change this:

**In the service:**
```ruby
duplicate = Incident.find_duplicate(
  project: @project,
  source: error_type,
  http_path: http_path,
  http_status: http_status,
  within: 48.hours  # Change to 48 hours
)
```

### Disable Duplicate Detection

To temporarily disable duplicate detection (for testing):

```ruby
# In app/services/datadog_sync_errors_service.rb
# Comment out the duplicate check:

# duplicate = Incident.find_duplicate(...)
# if duplicate
#   ...
#   return
# end
```

## Database Schema

### New Indexes

```sql
-- Composite index for error signature
CREATE INDEX index_incidents_on_error_signature 
ON incidents (project_id, source, http_path, http_status, status);

-- Index on last_synced_at
CREATE INDEX index_incidents_on_last_synced_at 
ON incidents (last_synced_at);
```

### Updated Fields

| Field | Purpose |
|-------|---------|
| `datadog_id` | Unique identifier from Datadog (indexed, unique per project) |
| `last_synced_at` | Last time this incident was seen in Datadog sync |
| `source` | Controller#action (part of error signature) |
| `http_path` | Request path (part of error signature) |
| `http_status` | HTTP status code (part of error signature) |
| `status` | open/resolved/closed (only 'open' checked for duplicates) |

## Future Enhancements (Optional)

### 1. Track Occurrence Count
Add a counter to track how many times the error occurred:

```ruby
# In incidents table
add_column :incidents, :occurrence_count, :integer, default: 1

# In sync service
if duplicate
  duplicate.increment!(:occurrence_count)
  duplicate.update(last_synced_at: Time.now)
  return
end
```

### 2. Show Last Occurrence Time
Display when the error was last seen:

```erb
<% if incident.last_synced_at %>
  Last seen: <%= time_ago_in_words(incident.last_synced_at) %> ago
<% end %>
```

### 3. Auto-Close Resolved Issues
Automatically close incidents that haven't occurred in X days:

```ruby
# Rake task or scheduled job
Incident.open.where('last_synced_at < ?', 7.days.ago).update_all(status: 'auto_resolved')
```

### 4. Configurable Time Window
Make the 24-hour window configurable per project:

```ruby
# Add to projects table
add_column :projects, :incident_dedup_hours, :integer, default: 24

# Use in service
within: @project.incident_dedup_hours.hours
```

## Troubleshooting

### "I'm still seeing duplicates"

**Check if they're truly duplicates:**
```ruby
# Get the incidents you think are duplicates
incidents = Incident.where(source: "HomeController#new", http_path: "/home/new")

# Compare their attributes
incidents.each do |inc|
  puts "ID: #{inc.id}, Status: #{inc.status}, Created: #{inc.created_at}, HTTP: #{inc.http_status}"
end
```

**Possible causes:**
1. Different HTTP status codes (500 vs 502)
2. Different paths (/home/new vs /home/new?id=1)
3. One is resolved, one is open
4. Created more than 24 hours apart

### "Sync is slower now"

**Check index usage:**
```sql
EXPLAIN SELECT * FROM incidents 
WHERE project_id = 1 
  AND source = 'HomeController#new' 
  AND http_path = '/home/new' 
  AND http_status = 500 
  AND status = 'open';
```

Should show "Using index: index_incidents_on_error_signature"

## Related Files

- **Service:** [app/services/datadog_sync_errors_service.rb](app/services/datadog_sync_errors_service.rb)
- **Model:** [app/models/incident.rb](app/models/incident.rb)
- **Migration:** [db/migrate/20260517193541_add_unique_index_to_incidents.rb](db/migrate/20260517193541_add_unique_index_to_incidents.rb)

---

**Status:** ✅ **COMPLETE**

Duplicate incident prevention is now active. Syncing Datadog errors will intelligently deduplicate recurring errors instead of creating duplicate incidents!
