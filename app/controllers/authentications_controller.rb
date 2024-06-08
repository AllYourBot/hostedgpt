class AuthenticationsController < ApplicationController
  require_unauthenticated_access only: [:new, :create]
  before_action :ensure_manual_login_allowed, except: :destroy

  layout "public"

  def new
  end

  def create
    person = Person.find_by(email: params[:email])
    @user = person&.personable

    if person.present? && @user&.password_credential&.authenticate(params[:password])
      login_as(person, credential: @user.password_credential)
      redirect_to root_path
      return
    end

    flash.now[:alert] = "Invalid email or password"
    render :new, status: :unprocessable_entity
  end

  def destroy
    logout_current
    redirect_to login_path
  end
end
