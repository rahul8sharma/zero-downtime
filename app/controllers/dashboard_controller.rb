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
    # Get projects with Datadog configured OR use environment variables for all projects
    @projects = Project.all

    if @projects.empty?
      redirect_to dashboard_incidents_path, alert: 'No projects found.'
      return
    end

    # Check if we have global Datadog credentials
    global_dd_api_key = ENV['DD_API_KEY']
    global_dd_app_key = ENV['DD_APP_KEY']
    global_dd_site = ENV['DD_SITE'] || 'datadoghq.eu'

    # Ensure projects have credentials (use global if not set)
    @projects.each do |project|
      if project.datadog_api_key.blank? && global_dd_api_key.present?
        project.update_columns(
          datadog_api_key: global_dd_api_key,
          datadog_app_key: global_dd_app_key,
          datadog_site: global_dd_site
        )
      end
    end

    Activity.log(
      action: 'datadog_sync_started',
      project: nil,
      details: "Started syncing errors from Datadog for #{@projects.count} project(s)"
    )

    total_synced = 0
    errors = []

    @projects.each do |project|
      result = DatadogSyncErrorsService.new(project).perform

      if result[:success]
        total_synced += result[:count]
      else
        errors << "#{project.name}: #{result[:error]}"
      end
    end

    if errors.any?
      redirect_to dashboard_incidents_path, alert: "Sync completed with errors: #{errors.join(', ')}"
    else
      redirect_to dashboard_incidents_path, notice: "Successfully synced #{total_synced} errors from Datadog!"
    end
  end
end
