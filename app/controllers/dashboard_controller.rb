class DashboardController < ApplicationController
  def index
    @projects = Project.all
    @incidents = Incident.includes(:project).open.recent.limit(10)
  end

  def logs_explorer
    @projects = Project.all
  end

  def alert_rules
    @projects = Project.all
  end

  def projects_page
    @projects = Project.all
  end

  def analytics
    @projects = Project.all
  end

  def activity
    @projects = Project.all
    @activities = Activity.order(created_at: :desc).limit(100)
  end

  def alerts
    @projects = Project.all
  end

  def reports
    @projects = Project.all
  end

  def settings
    @projects = Project.all
  end

  def sync_datadog_errors
    @projects = Project.where.not(datadog_api_key: nil)

    if @projects.empty?
      redirect_to root_path, alert: 'No projects with Datadog connected.'
      return
    end

    @projects.each do |project|
      DatadogSyncErrorsJob.perform_later(project.id)
    end

    Activity.log(
      action: 'datadog_sync_started',
      project: nil,
      details: "Started syncing errors from Datadog for #{@projects.count} project(s)"
    )

    redirect_to root_path, notice: "Syncing errors from Datadog in background for #{@projects.count} project(s)..."
  end
end
