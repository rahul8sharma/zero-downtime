class GithubController < ApplicationController
  def callback
    auth = request.env['omniauth.auth']

    # Get project ID from session
    project_id = session[:github_project_id]

    if project_id && auth
      project = Project.find(project_id)

      # Store GitHub OAuth data
      project.update(
        github_uid: auth['uid'],
        github_token: auth['credentials']['token'],
        github_username: auth['info']['nickname']
      )

      # Clear session
      session.delete(:github_project_id)

      redirect_to dashboard_projects_page_path, notice: 'GitHub connected successfully!'
    else
      redirect_to dashboard_projects_page_path, alert: 'Failed to connect GitHub.'
    end
  end

  def failure
    redirect_to dashboard_projects_page_path, alert: 'GitHub authentication failed.'
  end
end
