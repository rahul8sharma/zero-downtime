# Activity Logging Audit Report

## Summary

Activity logging is **mostly complete** but could be enhanced with a few additional events. Below is a comprehensive audit of what's currently logged and what's missing.

## Currently Logged Activities ✅

### Project Management
| Action | Icon | Location | Details |
|--------|------|----------|---------|
| `project_created` | ✨ | [projects_controller.rb:L14](app/controllers/projects_controller.rb#L14) | When a new project is created |
| `github_connected` | 📦 | [projects_controller.rb:L35](app/controllers/projects_controller.rb#L35) | When GitHub repo is connected |
| `datadog_connected` | 📊 | [projects_controller.rb:L56](app/controllers/projects_controller.rb#L56) | When Datadog is configured |

### GitHub OAuth
| Action | Icon | Location | Details |
|--------|------|----------|---------|
| `github_authenticated` | 🔐 | [github_controller.rb:L25](app/controllers/github_controller.rb#L25) | User authenticates with GitHub |

### Datadog Sync
| Action | Icon | Location | Details |
|--------|------|----------|---------|
| `datadog_sync_started` | 🔄 | [dashboard_controller.rb:L87](app/controllers/dashboard_controller.rb#L87) | Sync initiated |
| `datadog_sync_completed` | ✅ | [datadog_sync_errors_service.rb:L80](app/services/datadog_sync_errors_service.rb#L80) | Sync successful |
| `datadog_sync_failed` | ❌ | [datadog_sync_errors_service.rb:L100](app/services/datadog_sync_errors_service.rb#L100) | Sync failed (HTTP error) |
| `datadog_sync_error` | ⚠️ | [datadog_sync_errors_service.rb:L112](app/services/datadog_sync_errors_service.rb#L112) | Sync exception |

### AI PR Creation
| Action | Icon | Location | Details |
|--------|------|----------|---------|
| `pr_created_with_ai` | 🤖 | [generate_pr_with_ai_service.rb:L90](app/services/generate_pr_with_ai_service.rb#L90) | PR created successfully |
| `pr_creation_failed` | 🚫 | [generate_pr_with_ai_service.rb:L110](app/services/generate_pr_with_ai_service.rb#L110) | PR creation failed |

## Missing Activities (Recommendations) ⚠️

### High Priority - Should Add

1. **Incident Status Changes**
   - `incident_created` 🔥 - When new incident is created
   - `incident_resolved` ✔️ - When incident is marked resolved
   - `incident_reopened` 🔄 - When resolved incident reopens
   - `incident_closed` 🔒 - When incident is closed

2. **PR Status Updates**
   - `pr_merged` 🎉 - When AI-generated PR is merged
   - `pr_closed` ⛔ - When PR is closed without merging
   - `pr_updated` 📝 - When PR is updated

3. **Batch Operations**
   - `batch_pr_creation_started` 🚀 - When batch PR creation begins
   - `batch_pr_creation_completed` ✅ - When batch completes

### Medium Priority - Nice to Have

4. **Project Updates**
   - `project_updated` 📝 - When project settings change
   - `project_deleted` 🗑️ - When project is deleted
   - `github_disconnected` 🔌 - When GitHub is disconnected
   - `datadog_disconnected` 🔌 - When Datadog is disconnected

5. **Incident Management**
   - `incident_assigned` 👤 - When incident assigned to user
   - `incident_priority_changed` ⚡ - When severity changes
   - `incident_commented` 💬 - When comment added

6. **System Events**
   - `user_login` 🔐 - When user logs in
   - `user_logout` 🚪 - When user logs out
   - `settings_changed` ⚙️ - When system settings change

### Low Priority - Optional

7. **Search & Filter**
   - `search_performed` 🔍 - Track search patterns
   - `filter_applied` 🎯 - Track filter usage

8. **Export Operations**
   - `report_generated` 📄 - When reports exported
   - `data_exported` 💾 - When data exported

## Implementation Examples

### 1. Log Incident Creation

**Add to `app/services/datadog_sync_errors_service.rb`** after line 211:

```ruby
Activity.log(
  action: 'incident_created',
  project: @project,
  details: "New incident: #{title[0..70]}"
)
```

### 2. Log Incident Status Changes

**Create `app/models/concerns/activity_trackable.rb`:**

```ruby
module ActivityTrackable
  extend ActiveSupport::Concern

  included do
    after_update :log_status_change, if: :saved_change_to_status?
  end

  private

  def log_status_change
    Activity.log(
      action: "incident_#{status}",
      project: project,
      details: "Incident ##{id} status changed to #{status}"
    )
  end
end
```

**Include in `app/models/incident.rb`:**

```ruby
class Incident < ApplicationRecord
  include ActivityTrackable
  # ... rest of the model
end
```

### 3. Log Batch PR Creation

**Add to `app/controllers/incidents_controller.rb`** in `create_pr_for_project`:

```ruby
# Before the loop
Activity.log(
  action: 'batch_pr_creation_started',
  project: @project,
  details: "Starting batch PR creation for #{incidents.count} incidents"
)

# After the loop
Activity.log(
  action: 'batch_pr_creation_completed',
  project: @project,
  details: "Batch PR creation completed: #{created_count} successful"
)
```

## Current Activity Log Display

The activity log at `/dashboard/activity` shows:

- ✅ **Icon-based visualization** - Each action has a unique emoji
- ✅ **Timestamp** - "X ago" format
- ✅ **Project context** - Shows which project
- ✅ **Detailed message** - Human-readable description
- ✅ **Recent first** - Ordered by `created_at DESC`
- ✅ **Limit 100** - Shows last 100 activities

### Example Activity Log Output

```
🔄  5 minutes ago - Started syncing errors from Datadog for 1 project(s)
✅  5 minutes ago - Synced 3 errors from Datadog APM - Zero Downtime
🤖  10 minutes ago - Created PR #42 for incident #5: https://github.com/... - Zero Downtime
📦  1 hour ago - Connected GitHub repository: user/repo - Zero Downtime
✨  2 hours ago - Created project: Zero Downtime
```

## Database Schema

```sql
CREATE TABLE activities (
  id BIGINT PRIMARY KEY,
  action VARCHAR(255) NOT NULL,           -- Action type (e.g., 'project_created')
  project_id BIGINT,                      -- Associated project (optional)
  details TEXT,                           -- Human-readable description
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Indexes
CREATE INDEX index_activities_on_project_id ON activities (project_id);
CREATE INDEX index_activities_on_created_at ON activities (created_at DESC);
```

## Activity Log Controller

**Location:** `app/controllers/dashboard_controller.rb`

```ruby
def activity
  @projects = Project.all
  @activities = Activity.order(created_at: :desc).limit(100)
end
```

**Recommendations:**
1. Add pagination (currently limited to 100)
2. Add filtering by project
3. Add filtering by action type
4. Add date range filtering

## Activity Model

**Location:** `app/models/activity.rb`

```ruby
class Activity < ApplicationRecord
  belongs_to :project, optional: true

  def self.log(action:, project: nil, details: nil)
    create(
      action: action,
      project: project,
      details: details
    )
  end
end
```

**Recommendations:**
1. Add validation for action presence
2. Add enum for common actions
3. Add helper methods for filtering
4. Add scope for recent activities

## Enhanced Activity Model (Recommended)

```ruby
class Activity < ApplicationRecord
  belongs_to :project, optional: true

  validates :action, presence: true

  # Common action types
  enum action_category: {
    project: 0,
    github: 1,
    datadog: 2,
    incident: 3,
    pr: 4,
    system: 5
  }, _prefix: true

  # Scopes
  scope :recent, ->(limit = 100) { order(created_at: :desc).limit(limit) }
  scope :for_project, ->(project) { where(project: project) }
  scope :by_action, ->(action) { where(action: action) }
  scope :today, -> { where('created_at >= ?', Time.zone.now.beginning_of_day) }
  scope :this_week, -> { where('created_at >= ?', 1.week.ago) }

  # Helper to log with automatic categorization
  def self.log(action:, project: nil, details: nil)
    create(
      action: action,
      project: project,
      details: details,
      action_category: categorize_action(action)
    )
  end

  def self.categorize_action(action)
    case action.to_s
    when /^project_/ then :project
    when /^github_/ then :github
    when /^datadog_/ then :datadog
    when /^incident_/ then :incident
    when /^pr_/ then :pr
    else :system
    end
  end

  # Icon helper
  def icon
    case action
    when 'project_created' then '✨'
    when 'github_authenticated' then '🔐'
    when 'github_connected' then '📦'
    when 'datadog_connected' then '📊'
    when 'datadog_sync_started' then '🔄'
    when 'datadog_sync_completed' then '✅'
    when 'datadog_sync_failed' then '❌'
    when 'datadog_sync_error' then '⚠️'
    when 'pr_created_with_ai' then '🤖'
    when 'pr_creation_failed' then '🚫'
    when 'incident_created' then '🔥'
    when 'incident_resolved' then '✔️'
    when 'incident_closed' then '🔒'
    else '🔔'
    end
  end
end
```

## Enhanced Activity View

**Improved filtering UI:**

```erb
<div style="background: white; padding: 15px; border-radius: 8px; margin-bottom: 15px;">
  <%= form_with url: dashboard_activity_path, method: :get, local: true, style: "display: flex; gap: 10px; align-items: center;" do |f| %>
    <%= f.select :project_id,
        options_from_collection_for_select(@projects, :id, :name, params[:project_id]),
        { include_blank: 'All Projects' },
        style: "padding: 6px 10px; border: 1px solid #ddd; border-radius: 4px;" %>

    <%= f.select :action_type,
        options_for_select([
          ['All Activities', 'all'],
          ['Projects', 'project'],
          ['GitHub', 'github'],
          ['Datadog', 'datadog'],
          ['Incidents', 'incident'],
          ['Pull Requests', 'pr']
        ], params[:action_type]),
        {},
        style: "padding: 6px 10px; border: 1px solid #ddd; border-radius: 4px;" %>

    <%= f.submit "Filter", class: "btn btn-primary", style: "padding: 6px 16px;" %>
    <%= link_to "Reset", dashboard_activity_path, class: "btn btn-secondary", style: "padding: 6px 16px;" %>
  <% end %>
</div>
```

## Performance Considerations

### Current Performance
- ✅ **Fast queries** - Indexed on `created_at` and `project_id`
- ✅ **Limited results** - Max 100 activities loaded
- ✅ **No N+1** - Uses `includes(:project)` if needed

### Recommendations
1. Add pagination for large activity logs
2. Consider archiving old activities (> 90 days)
3. Add caching for activity counts
4. Add background job for non-critical activity logging

## Testing Activity Logging

### Rails Console Test

```ruby
# Check recent activities
Activity.recent(10).each do |a|
  puts "#{a.created_at} - #{a.action}: #{a.details}"
end

# Check activities by type
Activity.where("action LIKE ?", "datadog_%").count

# Check activities for a project
project = Project.first
Activity.for_project(project).count

# Create test activity
Activity.log(
  action: 'test_activity',
  project: Project.first,
  details: 'This is a test activity'
)
```

## Summary & Recommendations

### ✅ What's Working Well
1. All major operations are logged
2. Clean, simple logging API
3. Good icon visualization
4. Proper project association

### ⚠️ What's Missing
1. Incident lifecycle events (create, resolve, close)
2. PR status updates (merged, closed)
3. Batch operation logging
4. Filtering UI on activity page

### 🎯 Priority Actions

**High Priority:**
1. Add incident creation logging
2. Add incident status change tracking
3. Add batch PR creation logging

**Medium Priority:**
4. Add filtering to activity page UI
5. Add pagination
6. Enhanced activity model with enums

**Low Priority:**
7. Activity archiving
8. Export functionality
9. Real-time activity feed

## Related Files

- **Model:** [app/models/activity.rb](app/models/activity.rb)
- **View:** [app/views/dashboard/activity.html.erb](app/views/dashboard/activity.html.erb)
- **Controller:** [app/controllers/dashboard_controller.rb](app/controllers/dashboard_controller.rb)
- **Services:** Various services log activities

---

**Status:** ✅ **Activity logging is functional but can be enhanced**

The core activity logging is working well and captures the most important events. Consider implementing the high-priority recommendations for complete coverage.
