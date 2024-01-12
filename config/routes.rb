Rails.application.routes.draw do
  resources :assistants do
    get :instructions, to: "assistants/instructions#edit"
    patch :instructions, to: "assistants/instructions#update"
  end

  namespace "my" do
    resources :conversations, only: [:new, :create, :index]
  end

  shallow do
    resources :conversations, except: [:index, :new, :create] do
      resources :messages
    end
  end

  resources :documents

  resources :users, only: [:new, :create, :update]
  resources :chats, only: [:index, :show, :create]

  get "/register", to: "users#new"
  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  get "/logout", to: "sessions#destroy"

  get "/", to: "home#show", as: :dashboard
  get "up" => "rails/health#show", :as => :rails_health_check
end
