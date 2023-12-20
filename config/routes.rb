Rails.application.routes.draw do
  resources :projects do
    resources :tasks
  end

  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  resources :users, only: [:new, :create]
  get '/register', to: 'users#new'


  get "up" => "rails/health#show", :as => :rails_health_check
end
