Rails.application.routes.draw do
  root to: "assistants#index"

  resources :users, only: [:new, :create, :update]

  resources :assistants do
    resources :messages, only: [:new, :create, :edit]
  end

  resources :conversations, only: [:index, :show, :edit, :update, :destroy] do
    resources :messages, only: [:index]
  end

  resources :messages, only: [:show, :update]

  namespace :settings do
    resources :assistants, except: [:index, :show]
    resource :person, only: [:edit, :update]
    resources :language_models do
      get :test, to: "language_models#test"
    end
    resources :api_services, except: [:show]  do
      get :test, to: "api_services#test"
    end
    resources :memories, only: [:index, :destroy] do
      delete :destroy, to: "memories#destroy_all", on: :collection
    end
  end

  get "/login", to: "authentications#new"
  post "/login", to: "authentications#create"
  get "/register", to: "users#new"
  get "/logout", to: "authentications#destroy"

  if Feature.password_reset_email?
    resources :password_resets, only: [:new, :create]
    resource :password_credential, only: [:edit, :update]
  end

  get "/auth/microsoft_graph/callback" => "authentications/microsoft_graph_oauth#create", as: :microsoft_graph_oauth, provider: "microsoft_graph"
  get "/auth/:provider/callback" => "authentications/google_oauth#create", as: :google_oauth
  get "/auth/failure" => "authentications/google_oauth#failure" # connected in omniauth.rb

  # resources :documents  TODO: finish this feature

  get "/rails/active_storage/postgresql/:encoded_key/*filename" => "active_storage/postgresql#show", as: :rails_postgresql_service
  put "/rails/active_storage/postgresql/:encoded_token" => "active_storage/postgresql#update", as: :update_rails_postgresql_service

  get "up" => "rails/health#show", as: :rails_health_check
end
