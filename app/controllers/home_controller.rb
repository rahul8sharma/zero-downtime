class HomeController < ApplicationController
  def new
    fdffs
    # Display the form
  end

  def submit
    # Get form parameters
    @name = params[:name]
    @email = params[:email]
    @message = params[:message]
    @platform = params[:platform]

    # You can add validation or processing here
    if @name.present? && @email.present?
      flash[:success] = "Form submitted successfully!"
      @submission_successful = true
    else
      flash[:error] = "Please fill in all required fields."
      @submission_successful = false
    end

    # Render the submit page with the results
    render :submit
  end
end
