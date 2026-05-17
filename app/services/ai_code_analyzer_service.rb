class AiCodeAnalyzerService
  def initialize(project, incident)
    @project = project
    @incident = incident
    @client = Anthropic::Client.new(access_token: ENV['ANTHROPIC_API_KEY'])
  end

  def analyze_and_generate_fix
    puts "=" * 80
    puts "AI Analysis Starting..."
    puts "Incident: #{@incident.title}"
    puts "=" * 80

    # Check for demo mode
    if ENV['AI_DEMO_MODE'] == 'true'
      puts "⚡ DEMO MODE ENABLED - Using simulated AI response"
      return demo_response
    end

    # Fetch relevant code files from GitHub
    controller_code = fetch_controller_code

    return { success: false, error: 'Could not fetch controller code from GitHub' } unless controller_code

    # Build prompt for Claude
    prompt = build_analysis_prompt(controller_code)

    # Call Claude API
    response = call_claude_api(prompt)

    return { success: false, error: 'AI analysis failed' } unless response

    # Parse Claude's response and include the controller code
    result = parse_claude_response(response)
    result[:controller_code] = controller_code
    result
  rescue StandardError => e
    puts "AI Analysis Error: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def fetch_controller_code
    # Extract controller file path from incident source (e.g., "HomeController#new" -> "app/controllers/home_controller.rb")
    controller_name = @incident.source.split('#').first
    file_path = "app/controllers/#{controller_name.underscore}.rb"

    puts "Fetching code for: #{file_path}"

    github_service = GithubPrService.new(@project)
    github_service.fetch_file_content(file_path)
  rescue => e
    puts "Error fetching controller code: #{e.message}"
    nil
  end

  def build_analysis_prompt(controller_code)
    <<~PROMPT
      You are analyzing a production error in a Rails application and need to provide a complete, working fix.

      ## ERROR DETAILS
      - **Endpoint**: #{@incident.http_method} #{@incident.http_path}
      - **HTTP Status**: #{@incident.http_status}
      - **Controller/Action**: #{@incident.source}
      - **Duration**: #{@incident.duration_ms}ms
      - **Error Message**: #{@incident.error_message}

      ## CURRENT CODE
      ```ruby
      #{controller_code}
      ```

      ## TASK
      Provide a COMPLETE, WORKING version of the entire file with the bug fixed. Do not provide diffs or partial code - provide the full fixed file content.

      Your response must be JSON with these exact keys:
      {
        "root_cause": "Brief explanation of what's wrong (1-2 sentences)",
        "fixed_code": "THE COMPLETE FIXED FILE CONTENT - full working Ruby code ready to commit",
        "fix_description": "Detailed explanation of what was changed and why (2-3 paragraphs)",
        "testing_recommendations": ["specific test case 1", "specific test case 2", "specific test case 3"]
      }

      CRITICAL: The "fixed_code" field must contain the ENTIRE file with proper syntax, not just the changed lines.
    PROMPT
  end

  def call_claude_api(prompt)
    puts "Calling Claude API..."

    response = @client.messages(
      parameters: {
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: 2000,
        temperature: 1.0,
        messages: [
          { role: 'user', content: prompt }
        ]
      }
    )

    puts "Claude API response received"
    puts "Response structure: #{response.keys.inspect}"

    # Handle the response structure correctly
    if response['content'].is_a?(Array)
      response['content'][0]['text']
    elsif response['content'].is_a?(String)
      response['content']
    else
      response.dig('content', 0, 'text')
    end
  rescue => e
    puts "Claude API Error: #{e.message}"
    puts "Error class: #{e.class}"
    puts "Full error: #{e.inspect}"
    nil
  end

  def parse_claude_response(response_text)
    # Extract JSON from response (Claude might wrap it in markdown)
    json_match = response_text.match(/```json\n(.*?)\n```/m) || response_text.match(/{.*}/m)

    if json_match
      json_str = json_match[1] || json_match[0]
      parsed = JSON.parse(json_str)

      {
        success: true,
        root_cause: parsed['root_cause'],
        fixed_code: parsed['fixed_code'],
        fix_description: parsed['fix_description'],
        testing_recommendations: parsed['testing_recommendations']
      }
    else
      # Fallback: use raw response as fix description
      {
        success: true,
        root_cause: 'AI analysis completed',
        fixed_code: response_text,
        fix_description: response_text,
        testing_recommendations: ['Test the endpoint manually', 'Check server logs', 'Review error tracking']
      }
    end
  rescue JSON::ParserError => e
    puts "Error parsing Claude response: #{e.message}"
    # Return raw response as fallback
    {
      success: true,
      root_cause: 'Analysis completed but format was unexpected',
      fixed_code: response_text,
      fix_description: response_text,
      testing_recommendations: ['Verify the fix manually']
    }
  end

  def demo_response
    controller_name = @incident.source.split('#').first
    action_name = @incident.source.split('#').last

    # Generate a complete, realistic fixed controller file
    fixed_controller_code = <<~RUBY
      class #{controller_name} < ApplicationController
        def #{action_name}
          begin
            # Original functionality with added error handling
            @name = params[:name]
            @email = params[:email]
            @message = params[:message]
            @platform = params[:platform]

            # Validate required parameters
            if @name.blank? || @email.blank?
              flash[:error] = "Please fill in all required fields."
              @submission_successful = false
              render :#{action_name} and return
            end

            # Process the submission
            flash[:success] = "Form submitted successfully!"
            @submission_successful = true

            # Log success for monitoring
            Rails.logger.info("Form submission successful: \#{@name} <\#{@email}>")

          rescue StandardError => e
            # Catch any unexpected errors
            Rails.logger.error("Error in #{@incident.source}: \#{e.message}")
            Rails.logger.error(e.backtrace.join("\\n"))

            flash[:error] = "An unexpected error occurred. Please try again."
            @submission_successful = false

            # Notify error tracking service
            # Rollbar.error(e) if defined?(Rollbar)
          end

          render :submit
        end
      end
    RUBY

    {
      success: true,
      root_cause: "The #{@incident.source} action lacks proper error handling and validation, causing unhandled exceptions to bubble up as #{@incident.http_status} errors when invalid data is submitted or unexpected errors occur.",
      fixed_code: fixed_controller_code.strip,
      fix_description: "This fix adds comprehensive error handling to the #{@incident.source} action:\n\n1. **Input Validation**: Added blank checks for required fields (@name, @email) with early return and user-friendly error messages.\n\n2. **Exception Handling**: Wrapped the entire action in a rescue block to catch any unexpected StandardError exceptions, preventing #{@incident.http_status} errors from reaching users.\n\n3. **Proper Logging**: Added Rails.logger calls for both success and error cases, including full backtrace for errors to aid debugging.\n\n4. **Graceful Degradation**: On error, the user sees a friendly message and the form re-renders instead of seeing a server error page.\n\n5. **Error Tracking Integration**: Added comment showing where to integrate with Rollbar or similar error tracking services.\n\nThis approach improves user experience, makes debugging easier, and prevents the application from exposing internal errors to end users.",
      testing_recommendations: [
        "Test #{@incident.http_method} #{@incident.http_path} with valid form data (name, email, message) and verify success",
        "Test with missing required fields (blank name or email) and verify validation error message appears",
        "Test with invalid email format and verify appropriate error handling",
        "Check Rails logs to confirm both success and error cases are being logged properly",
        "Simulate an exception (e.g., database connection error) and verify the rescue block handles it gracefully"
      ],
      controller_code: fixed_controller_code.strip
    }
  end
end
