class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]


  def new
  end

  def create
    person = Person.find_by(email: params[:email])
    user = person&.personable

    if user && user.authenticate(params[:password])
      # User is authenticated
      # Set up the session and redirect as needed
      session[:user_id] = user.id
      Current.user = user
      redirect_to projects_path, notice: 'Successfully logged in.'
    else
      flash.now[:alert] = 'Invalid email or password'
      render :new
    end
  end
end
