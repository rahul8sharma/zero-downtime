require 'omniauth'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github,
    ENV['GITHUB_CLIENT_ID'],
    ENV['GITHUB_CLIENT_SECRET'],
    scope: 'repo,read:user,user:email'
end

# Fix for OmniAuth CSRF protection
OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true
