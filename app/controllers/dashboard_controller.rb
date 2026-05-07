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

  def incidents
    @projects = Project.all
    @incidents = Incident.includes(:project).recent

    # Filter by severity if provided
    if params[:severity].present? && params[:severity] != 'all'
      @incidents = @incidents.where(severity: params[:severity])
    end

    # Filter by status if provided
    if params[:status].present? && params[:status] != 'all'
      @incidents = @incidents.where(status: params[:status])
    end

    # Search by title or error message
    if params[:search].present?
      @incidents = @incidents.where("title LIKE ? OR error_message LIKE ?",
                                   "%#{params[:search]}%",
                                   "%#{params[:search]}%")
    end
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
      redirect_to dashboard_incidents_path, alert: 'No projects with Datadog connected.'
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

    redirect_to dashboard_incidents_path, notice: "Syncing errors from Datadog in background for #{@projects.count} project(s)..."
  end
end
