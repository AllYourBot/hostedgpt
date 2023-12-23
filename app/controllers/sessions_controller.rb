class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]

  def new
    if Current.user.present? || session[:user_id].present?
      redirect_to dashboard_path
    end
  end

  def create
    person = Person.find_by(email: params[:email])
    if person.blank?
      render :new
      flash.now[:alert] = "Invalid email or password"
      return
    end

    user = person&.personable

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: "Successfully logged in."
    else
      flash.now[:alert] = "Invalid email or password"
      render :new
    end
  end
end
