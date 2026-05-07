require 'net/http'
require 'json'

class GithubController < ApplicationController
  def callback
    code = params[:code]
    project_id = session[:github_project_id]

    if code && project_id
      # Exchange code for access token
      token_response = exchange_code_for_token(code)

      if token_response['access_token']
        # Get user info
        user_info = get_github_user(token_response['access_token'])

        # Update project with GitHub data (but not repo yet)
        project = Project.find(project_id)
        project.update(
          github_uid: user_info['id'].to_s,
          github_token: token_response['access_token'],
          github_username: user_info['login']
        )

        Activity.log(
          action: 'github_authenticated',
          project: project,
          details: "Authenticated with GitHub as @#{user_info['login']}"
        )

        # Redirect to repo selection page
        redirect_to select_repo_project_path(project)
      else
        session.delete(:github_project_id)
        redirect_to dashboard_projects_page_path, alert: 'Failed to get access token from GitHub.'
      end
    else
      session.delete(:github_project_id)
      redirect_to dashboard_projects_page_path, alert: 'Failed to connect GitHub. Missing authorization code.'
    end
  end

  def failure
    redirect_to dashboard_projects_page_path, alert: 'GitHub authentication failed.'
  end

  private

  def exchange_code_for_token(code)
    uri = URI('https://github.com/login/oauth/access_token')
    params = {
      client_id: ENV['GITHUB_CLIENT_ID'],
      client_secret: ENV['GITHUB_CLIENT_SECRET'],
      code: code
    }

    response = Net::HTTP.post_form(uri, params)
    parsed = URI.decode_www_form(response.body).to_h

    # GitHub returns the token in query string format, convert to hash
    parsed
  end

  def get_github_user(token)
    uri = URI('https://api.github.com/user')
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "token #{token}"
    request['Accept'] = 'application/json'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  end
end
