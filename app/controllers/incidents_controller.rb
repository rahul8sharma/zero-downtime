class IncidentsController < ApplicationController
  def create_pr
    @incident = Incident.find(params[:id])
    @project = @incident.project

    # Validate project has GitHub configured
    unless @project.github_token.present? && @project.github_repo_url.present?
      redirect_to dashboard_incidents_path,
        alert: 'GitHub is not connected for this project. Please connect GitHub first.'
      return
    end

    # Check if PR already exists
    if @incident.pr_created?
      redirect_to dashboard_incidents_path,
        notice: "PR already exists for this incident: #{@incident.pr_url}"
      return
    end

    # Generate PR with AI
    result = GeneratePrWithAiService.new(@project, @incident).perform

    if result[:success]
      redirect_to dashboard_incidents_path,
        notice: "🎉 PR created successfully! <a href='#{result[:pr_url]}' target='_blank'>View PR ##{result[:pr_number]}</a>".html_safe
    else
      redirect_to dashboard_incidents_path,
        alert: "Failed to create PR: #{result[:error]}"
    end
  end

  def create_pr_for_project
    @project = Project.find(params[:id])

    # Validate GitHub configuration
    unless @project.github_token.present? && @project.github_repo_url.present?
      redirect_to dashboard_incidents_path,
        alert: 'GitHub is not connected for this project. Please connect GitHub first.'
      return
    end

    # Get all open incidents without PRs
    incidents = @project.incidents.open.without_pr

    if incidents.empty?
      redirect_to dashboard_incidents_path,
        notice: 'No open incidents without PRs found.'
      return
    end

    # Create PRs for incidents (limit to 5 to avoid rate limits)
    created_count = 0
    errors = []

    incidents.limit(5).each do |incident|
      result = GeneratePrWithAiService.new(@project, incident).perform

      if result[:success]
        created_count += 1
      else
        errors << "#{incident.title}: #{result[:error]}"
      end

      # Add small delay to avoid GitHub API rate limiting
      sleep(2) if incidents.count > 1
    end

    if errors.any?
      redirect_to dashboard_incidents_path,
        alert: "Created #{created_count} PRs. Errors: #{errors.first(3).join('; ')}"
    else
      redirect_to dashboard_incidents_path,
        notice: "🎉 Successfully created #{created_count} PRs with AI!"
    end
  end
end
