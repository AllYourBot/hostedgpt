class SessionsController < ApplicationController
  include Accessible

  def new
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

  def destroy
    reset_session
    Current.user = nil
    redirect_to login_path, notice: "Successfully logged out."
  end
end
