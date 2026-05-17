Rails.application.routes.draw do
  # Projects routes
  resources :projects, only: [:index, :new, :create] do
    member do
      get 'connect_github'
      get 'select_repo'
      post 'save_repo'
      get 'connect_datadog'
      post 'save_datadog'
      post 'create_prs', to: 'incidents#create_pr_for_project'
    end
  end

  # Incidents routes
  resources :incidents, only: [] do
    member do
      post 'create_pr'
    end
  end

  # GitHub OAuth callback
  get '/auth/github/callback', to: 'github#callback'

  # Home controller routes
  get 'home/new'
  post 'home/submit'

  # Dashboard routes
  root 'dashboard#index'
  get 'dashboard/index'
  get 'dashboard/incidents'
  get 'dashboard/logs_explorer'
  get 'dashboard/alert_rules'
  get 'dashboard/projects_page'
  get 'dashboard/analytics'
  get 'dashboard/activity'
  get 'dashboard/alerts'
  get 'dashboard/reports'
  get 'dashboard/settings'
  post 'dashboard/sync_datadog_errors'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
