Rails.application.routes.draw do
  namespace :settings do
    resources :assistants, except: [:index, :show]
    resource :person, only: [:edit, :update]
  end

  root to: "assistants#index"

  resources :assistants do
    resources :messages, only: [:new, :create, :edit]
  end

  resources :conversations, only: [:show, :edit, :update, :destroy] do
    resources :messages, only: [:index]
  end

  resources :messages, only: [:show, :update]
  resources :documents
  resources :users, only: [:new, :create, :update]

  get "up" => "rails/health#show", as: :rails_health_check

  # routes to still be cleaned up:

  resources :chats, only: [:index, :show, :create]

  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  get "/register", to: "users#new"
  get "/logout", to: "sessions#destroy"

  get "/rails/active_storage/postgresql/:encoded_key/*filename" => "active_storage/postgresql#show", as: :rails_postgresql_service
  put "/rails/active_storage/postgresql/:encoded_token" => "active_storage/postgresql#update", as: :update_rails_postgresql_service
end
