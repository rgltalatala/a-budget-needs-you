Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  get "/health", to: "health#index"
  get "/ready", to: "health#ready"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check


  # API routes
  namespace :api do
    namespace :v1 do
      post "/sessions", to: "sessions#create"
      delete "/sessions", to: "sessions#destroy"
      
      resources :users, only: [:create] do
        collection do
          get :me
        end
      end
      patch "users/me/password", to: "passwords#update"
      post "password_reset_requests", to: "passwords#request_reset"
      post "password_reset", to: "passwords#reset"
      resources :accounts
      resources :account_groups
      resources :categories
      resources :transactions
      resources :budgets
      resources :budget_months do
        collection do
          post :transition
        end
      end
      resources :category_groups
      resources :category_months
      resources :goals
      resources :summaries
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
