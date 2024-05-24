class SessionsController < ApplicationController
  include Accessible

  layout "public"

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
end
