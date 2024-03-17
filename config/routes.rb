Rails.application.routes.draw do
  namespace :settings do
    resources :assistants, except: [:index, :show]
    resource :person, only: [:edit, :update]
  end

  root to: "assistants#index"

  resources :assistants do
    resources :messages, only: [:new, :create]
  end

  resources :conversations do
    resources :messages, only: :index
  end

  resources :messages, except: [:new, :create, :index]
  resources :documents
  resources :users, only: [:new, :create]

  get "up" => "rails/health#show", :as => :rails_health_check

  # routes to still be cleaned up:

  resources :chats, only: [:index, :show, :create]

  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  get "/logout", to: "sessions#destroy"
end
