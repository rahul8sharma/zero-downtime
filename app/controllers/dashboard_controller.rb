class DashboardController < ApplicationController
  def index
    @projects = Project.all
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

  def team
    @projects = Project.all
  end

  def activity
    @projects = Project.all
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
end
