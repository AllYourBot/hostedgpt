class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]

  def new
    if user_signed_in?
      redirect_to dashboard_path
    else
      render
    end
  end

  def create
    person = Person.find_by(email: params[:email])
    if person.blank?
      render :new
      flash.now[:alert] = "Invalid email or password"
      return
    end

    @user = person&.personable

    if @user&.authenticate(params[:password])
      reset_session
      session[:current_user_id] = @user.id
      redirect_to dashboard_path, notice: "Successfully logged in."
    else
      flash.now[:alert] = "Invalid email or password"
      render :new
    end
  end
end
