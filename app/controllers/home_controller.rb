class HomeController < ApplicationController
  def new
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
        render :new and return
      end

      # Process the submission
      flash[:success] = "Form submitted successfully!"
      @submission_successful = true

      # Log success for monitoring
      Rails.logger.info("Form submission successful: #{@name} <#{@email}>")

    rescue StandardError => e
      # Catch any unexpected errors
      Rails.logger.error("Error in HomeController#new: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      flash[:error] = "An unexpected error occurred. Please try again."
      @submission_successful = false

      # Notify error tracking service
      # Rollbar.error(e) if defined?(Rollbar)
    end

    render :submit
  end
end