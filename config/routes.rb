Rails.application.routes.draw do
  resources :features do
    collection do
      put :reorder
      patch :reorder
    end
  end
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

  post "payments/create-subscription", to: "payments#create_subscription"
  post "payments/subscription-complete", to: "payments#payment_complete"
  post 'payments/purchase', to: 'payments#create_payment_intent'
  post 'payments/purchase-complete', to: 'payments#one_time_payment_complete'
  get 'payments/price', to: 'payments#price'

  namespace :api do
    namespace :v1, format: :json do
      # JSON auth for mobile / API clients
      post   "sessions",      to: "sessions#create"      # sign in
      delete "sessions",      to: "sessions#destroy"     # sign out (rotates token)
      post   "registrations", to: "registrations#create" # sign up

      get "users/current", to: "users#current"
      get "users", to: "users#index"
      get "users/:id", to: "users#show"

      resources :funnels do
        collection do
          get :metrics
        end
      end
    end
  end

  # Marketing funnel landing pages
  scope "/f/:funnel_slug", as: "funnel" do
    get "lead",            to: "landing_pages#lead_page",            as: "lead"
    get "book-call",       to: "landing_pages#book_call_page",       as: "book_call"
    get "order",           to: "landing_pages#order_page",           as: "order"
    get "order-completed", to: "landing_pages#order_completed_page", as: "order_completed"
  end

  # Defines the root path route ("/")
  root "static#index"

  get "app", to: "static#app", as: "app"
  get "app/*other" => "static#app"

  get "react-app", to: "static#react_app", as: "react_app"
  get "react-app/*other" => "static#react_app"

  get "admin", to: "static#admin", as: "admin"
  get "admin/*other" => "static#admin"
end
