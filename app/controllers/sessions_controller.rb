class SessionsController < ApplicationController
  include Accessible

  def new
  end

  def create
    person = Person.find_by(email: params[:email].strip)

    if person.blank?
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
      return
    end

    @user = person&.personable

    if @user&.authenticate(params[:password])
      reset_session
      login_as @user
      redirect_to root_path
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    Current.user = nil
    redirect_to login_path
  end
end
