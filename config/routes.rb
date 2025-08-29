Rails.application.routes.draw do
  get "about", to: "static#about", as: "about"
  get "simple", to: "static#simple", as: "simple"
  get "privacy", to: "static#privacy", as: "privacy"
  get "terms", to: "static#terms", as: "terms"
  get "dark-theme", to: "static#dark", as: "dark_theme"

  devise_for :users, path_names: { sign_in: "sign-in", sign_up: "register", sign_out: "logout" },
             controllers: { registrations: "registrations" }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :articles
  resources :contacts
  resources :email_templates, path: 'email-templates'
  post "email-templates/:id/send", to: "email_templates#send_to_list"

  namespace :api do
    namespace :v1, format: :json do
      get "users/current", to: "users#current"
      get "users", to: "users#index"
      get "users/:id", to: "users#show"
    end
  end

  # Defines the root path route ("/")
  root "static#index"

  get "app", to: "static#app", as: "app"
  get "app/*other" => "static#app"

  get "admin", to: "static#admin", as: "admin"
  get "admin/*other" => "static#admin"
end
