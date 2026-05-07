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
      Activity.log(
        action: 'project_created',
        project: @project,
        details: "Created project: #{@project.name}"
      )
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

  def select_repo
    @project = Project.find(params[:id])

    # Fetch repositories from GitHub
    @repositories = fetch_github_repos(@project.github_token)

    # Clear session
    session.delete(:github_project_id)
  end

  def save_repo
    @project = Project.find(params[:id])
    repo_full_name = params[:repository]

    if repo_full_name.present?
      @project.update(github_repo_url: "https://github.com/#{repo_full_name}")
      Activity.log(
        action: 'github_connected',
        project: @project,
        details: "Connected GitHub repository: #{repo_full_name}"
      )
      redirect_to dashboard_projects_page_path, notice: "Repository #{repo_full_name} connected successfully!"
    else
      @repositories = fetch_github_repos(@project.github_token)
      flash.now[:alert] = 'Please select a repository'
      render :select_repo
    end
  end

  def connect_datadog
    @project = Project.find(params[:id])
  end

  def save_datadog
    @project = Project.find(params[:id])

    if @project.update(datadog_params)
      Activity.log(
        action: 'datadog_connected',
        project: @project,
        details: "Connected Datadog monitoring (Site: #{@project.datadog_site})"
      )
      redirect_to dashboard_projects_page_path, notice: 'Datadog connected successfully!'
    else
      render :connect_datadog
    end
  end

  private

  def fetch_github_repos(token)
    require 'net/http'
    require 'json'

    uri = URI('https://api.github.com/user/repos')
    uri.query = URI.encode_www_form(
      sort: 'updated',
      per_page: 100,
      type: 'all'
    )

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "token #{token}"
    request['Accept'] = 'application/vnd.github.v3+json'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code == '200'
      JSON.parse(response.body)
    else
      []
    end
  end

  def project_params
    params.require(:project).permit(:name, :description)
  end

  def datadog_params
    params.require(:project).permit(:datadog_api_key, :datadog_app_key, :datadog_site)
  end
end
