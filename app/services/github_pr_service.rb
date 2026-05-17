class GithubPrService
  def initialize(project)
    @project = project
    @token = project.github_token
    @repo_url = project.github_repo_url

    # Parse owner and repo from URL (e.g., "https://github.com/owner/repo")
    uri = URI.parse(@repo_url)
    path_parts = uri.path.split('/').reject(&:empty?)
    @owner = path_parts[0]
    @repo = path_parts[1]&.gsub('.git', '')
  end

  def fetch_file_content(file_path)
    uri = URI("https://api.github.com/repos/#{@owner}/#{@repo}/contents/#{file_path}")

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['Accept'] = 'application/vnd.github.v3+json'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code == '200'
      data = JSON.parse(response.body)
      # Content is base64 encoded
      Base64.decode64(data['content'])
    else
      puts "Failed to fetch file: #{response.code} - #{response.body}"
      nil
    end
  rescue => e
    puts "Error fetching file from GitHub: #{e.message}"
    nil
  end

  def get_default_branch
    uri = URI("https://api.github.com/repos/#{@owner}/#{@repo}")

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['Accept'] = 'application/vnd.github.v3+json'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code == '200'
      data = JSON.parse(response.body)
      data['default_branch'] || 'main'
    else
      'main'  # Fallback to main
    end
  rescue => e
    puts "Error fetching default branch: #{e.message}"
    'main'
  end

  def get_branch_sha(branch_name)
    uri = URI("https://api.github.com/repos/#{@owner}/#{@repo}/git/refs/heads/#{branch_name}")

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['Accept'] = 'application/vnd.github.v3+json'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code == '200'
      data = JSON.parse(response.body)
      data.dig('object', 'sha')
    else
      nil
    end
  rescue => e
    puts "Error fetching branch SHA: #{e.message}"
    nil
  end

  def create_branch(branch_name, base_branch = nil)
    base_branch ||= get_default_branch
    base_sha = get_branch_sha(base_branch)

    return { success: false, error: 'Could not get base branch SHA' } unless base_sha

    uri = URI("https://api.github.com/repos/#{@owner}/#{@repo}/git/refs")

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['Accept'] = 'application/vnd.github.v3+json'
    request['Content-Type'] = 'application/json'
    request.body = {
      ref: "refs/heads/#{branch_name}",
      sha: base_sha
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code == '201'
      puts "✓ Branch created: #{branch_name}"
      { success: true, branch: branch_name }
    else
      error_data = JSON.parse(response.body) rescue { 'message' => response.body }
      { success: false, error: "Failed to create branch: #{error_data['message']}" }
    end
  rescue => e
    { success: false, error: "Error creating branch: #{e.message}" }
  end

  def create_or_update_file(file_path, content, commit_message, branch_name)
    # First, get the current file SHA if it exists
    uri = URI("https://api.github.com/repos/#{@owner}/#{@repo}/contents/#{file_path}?ref=#{branch_name}")

    get_request = Net::HTTP::Get.new(uri)
    get_request['Authorization'] = "Bearer #{@token}"
    get_request['Accept'] = 'application/vnd.github.v3+json'

    get_response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(get_request)
    end

    file_sha = nil
    if get_response.code == '200'
      file_data = JSON.parse(get_response.body)
      file_sha = file_data['sha']
    end

    # Now create or update the file
    put_uri = URI("https://api.github.com/repos/#{@owner}/#{@repo}/contents/#{file_path}")

    put_request = Net::HTTP::Put.new(put_uri)
    put_request['Authorization'] = "Bearer #{@token}"
    put_request['Accept'] = 'application/vnd.github.v3+json'
    put_request['Content-Type'] = 'application/json'

    body = {
      message: commit_message,
      content: Base64.strict_encode64(content),
      branch: branch_name
    }
    body[:sha] = file_sha if file_sha

    put_request.body = body.to_json

    response = Net::HTTP.start(put_uri.hostname, put_uri.port, use_ssl: true) do |http|
      http.request(put_request)
    end

    if ['200', '201'].include?(response.code)
      puts "✓ File committed: #{file_path}"
      { success: true }
    else
      error_data = JSON.parse(response.body) rescue { 'message' => response.body }
      { success: false, error: "Failed to commit file: #{error_data['message']}" }
    end
  rescue => e
    { success: false, error: "Error committing file: #{e.message}" }
  end

  def create_pull_request(title, body, head_branch, base_branch = nil)
    base_branch ||= get_default_branch

    uri = URI("https://api.github.com/repos/#{@owner}/#{@repo}/pulls")

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['Accept'] = 'application/vnd.github.v3+json'
    request['Content-Type'] = 'application/json'
    request.body = {
      title: title,
      body: body,
      head: head_branch,
      base: base_branch
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code == '201'
      pr_data = JSON.parse(response.body)
      puts "✓ PR created: #{pr_data['html_url']}"
      {
        success: true,
        pr_url: pr_data['html_url'],
        pr_number: pr_data['number'],
        pr_status: pr_data['state']
      }
    else
      error_data = JSON.parse(response.body) rescue { 'message' => response.body }
      { success: false, error: "Failed to create PR: #{error_data['message']}" }
    end
  rescue => e
    { success: false, error: "Error creating PR: #{e.message}" }
  end
end
