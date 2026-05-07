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

    # Build GitHub OAuth URL manually
    client_id = ENV['GITHUB_CLIENT_ID']
    redirect_uri = "#{request.base_url}/auth/github/callback"
    scope = 'repo,read:user,user:email'

    github_url = "https://github.com/login/oauth/authorize?" \
                 "client_id=#{client_id}" \
                 "&redirect_uri=#{CGI.escape(redirect_uri)}" \
                 "&scope=#{CGI.escape(scope)}"

    redirect_to github_url, allow_other_host: true
  end

  private

  def project_params
    params.require(:project).permit(:name, :description)
  end
end
