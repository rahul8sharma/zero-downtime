class Incident < ApplicationRecord
  belongs_to :project

  validates :title, presence: true
  validates :datadog_id, uniqueness: { scope: :project_id }, allow_nil: true

  scope :open, -> { where(status: 'open') }
  scope :recent, -> { order(created_at: :desc) }
  scope :critical, -> { where(severity: 'critical') }
  scope :by_controller, ->(controller) { where(source: controller) }
  scope :with_pr, -> { where.not(pr_url: nil) }
  scope :without_pr, -> { where(pr_url: nil) }

  # Generate PR description from incident trace data
  def pr_description
    <<~DESC
      ## Fix: #{title}

      **Error Details:**
      - Endpoint: `#{http_method} #{http_path}`
      - HTTP Status: #{http_status}
      - Controller/Action: #{source}
      - Duration: #{duration_ms&.round(2)}ms
      - Severity: **#{severity.upcase}**
      - Service: #{service}

      **Error Message:**
      ```
      #{error_message}
      ```

      #{trace_url ? "**Datadog Trace:** #{trace_url}\n" : ""}
      #{stack_trace ? "**Stack Trace Available:** Yes\n" : ""}

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

      Fixes incident ##{id} | First seen: #{created_at.strftime('%Y-%m-%d %H:%M UTC')}
    DESC
  end

  # Generate branch name for this fix
  def suggested_branch_name
    "fix/#{source.parameterize}-#{http_status}-error"
  end

  # Generate PR title
  def suggested_pr_title
    "Fix #{http_status} error in #{source}"
  end

  # Summary for quick reference
  def trace_summary
    {
      endpoint: "#{http_method} #{http_path}",
      status: http_status,
      duration: "#{duration_ms&.round(2)}ms",
      controller: source,
      severity: severity,
      trace_url: trace_url
    }
  end

  # Check if PR has been created for this incident
  def pr_created?
    pr_url.present?
  end

  # PR status badge color
  def pr_status_color
    case pr_status
    when 'merged'
      '#6f42c1'  # Purple
    when 'closed'
      '#dc3545'  # Red
    else
      '#28a745'  # Green (open)
    end
  end
end
