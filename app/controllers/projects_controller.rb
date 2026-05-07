class ProjectsController < ApplicationController
  def index
    @projects = Project.all
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)

    if @project.save
      redirect_to projects_path, notice: 'Project was successfully created.'
    else
      render :new
    end
  end

  def connect_github
    @project = Project.find(params[:id])

    # Store project ID in session for callback
    session[:github_project_id] = @project.id

    # Redirect to GitHub OAuth
    redirect_to '/auth/github', allow_other_host: true
  end

  private

  def project_params
    params.require(:project).permit(:name, :description)
  end
end
