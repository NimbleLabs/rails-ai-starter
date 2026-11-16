Rails.application.routes.draw do
  # Dynamic branding: favicon and OG image derived from config/app.yml
  get "favicon.svg", to: "branding#favicon", as: "favicon"
  get "og-image.png", to: "branding#og_image", as: "og_image"

  get "about", to: "static#about", as: "about"
  get "simple", to: "static#simple", as: "simple"
  get "privacy", to: "static#privacy", as: "privacy"
  get "terms", to: "static#terms", as: "terms"
  get "dark-theme", to: "static#dark", as: "dark_theme"
  get "whats-new", to: "whats_new#show", as: "whats_new"

  devise_for :users, path_names: { sign_in: "sign-in", sign_up: "register", sign_out: "logout" },
             controllers: {
               registrations: "registrations",
               sessions: "users/sessions",
               omniauth_callbacks: "users/omniauth_callbacks"
             }

  # MCP server (see McpServer) and the OAuth 2.1 endpoints its clients use:
  # /oauth/authorize (the consent page), /oauth/token and /oauth/revoke from
  # Doorkeeper, plus client registration and the discovery documents.
  use_doorkeeper do
    skip_controllers :applications, :authorized_applications, :token_info
  end
  post "oauth/register", to: "oauth_client_registrations#create"
  get ".well-known/oauth-protected-resource(/mcp)", to: "well_known#oauth_protected_resource", format: false
  get ".well-known/oauth-authorization-server", to: "well_known#oauth_authorization_server", format: false
  match "mcp", to: "mcp#handle", via: %i[get post delete], format: false

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # /up checks the database, migrations, required tables and the cache, not
  # merely that the app booted. See HealthController.
  get "up" => "health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :articles
  resources :contacts
  resources :email_templates, path: "email-templates"
  post "email-templates/:id/send", to: "email_templates#send_to_list"

  # Admin dashboard metrics (Ahoy) — consumed by the React admin
  get "dashboard/metrics", to: "dashboard#metrics"

  # Test suite report card (QualityReport) — consumed by the React admin at /admin/quality
  get "quality", to: "quality#show"

  # config/app.yml's name and look (AppConfig) — the React admin at /admin/theme
  # previews changes and, in development, saves them
  get "theme", to: "theme#show"
  match "theme", to: "theme#update", via: %i[put patch]
  post "theme/preview", to: "theme#preview"

  # Internal error log (admin JSON; React admin at /admin/logs)
  resources :logs, only: %i[index show update destroy] do
    collection do
      patch  :resolve_all
      put    :resolve_all
      delete :destroy_resolved
    end
  end
  resources :log_subscriptions, path: "log-subscriptions", only: %i[index create update destroy] do
    member { post :test }
  end

  # NimbleHQ reads one day of traffic a night (see Api::MetricsController)
  get "api/metrics/daily", to: "api/metrics#daily"

  namespace :api do
    namespace :v1, format: :json do
      # JSON auth for mobile / API clients
      post   "sessions",      to: "sessions#create"      # sign in
      delete "sessions",      to: "sessions#destroy"     # sign out (rotates token)
      post   "registrations", to: "registrations#create" # sign up

      get "users/current", to: "users#current"
      get "users", to: "users#index"
      get "users/:id", to: "users#show"

      # Mobile error reporting → internal Log (see Api::V1::LogsController)
      post "logs", to: "logs#create"
      # Mobile analytics → Ahoy (see Api::V1::EventsController)
      post "events", to: "events#create"
    end
  end

  # Defines the root path route ("/")
  root "static#index"

  get "app", to: "static#app", as: "app"
  get "app/*other" => "static#app"

  get "admin", to: "static#admin", as: "admin"
  get "admin/*other" => "static#admin"
end
