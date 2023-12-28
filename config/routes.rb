Rails.application.routes.draw do
  mount GoodJob::Engine => 'good_job'

  resources :assistants
  resources :conversations
  resources :messages
  resources :documents

  resources :users, only: [:new, :create]
  resources :chats, only: [:index, :show, :create]

  get "/register", to: "users#new"
  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  get "/logout", to: "sessions#destroy"

  get "/", to: "home#show", as: :dashboard
  get "up" => "rails/health#show", :as => :rails_health_check
end
