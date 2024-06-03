class SessionsController < ApplicationController
  include Accessible

  layout "public"

  before_action :ensure_authentication_allowed

  def new
  end

  def create
    person = Person.find_by(email: params[:email])
    @user = person&.personable

    if person.present? && @user&.authenticate(params[:password])
      login_as @user
      redirect_to root_path
      return
    end

    flash.now[:alert] = "Invalid email or password"
    render :new, status: :unprocessable_entity
  end

  def destroy
    reset_session
    Current.user = nil
    redirect_to login_path
  end

  private

  def ensure_authentication_allowed
    if Feature.disabled?(:password_authentication) && Feature.disabled?(:google_authentication)
      redirect_to root_path, alert: "Password and Google authentication are both disabled."
    end
  end
end
