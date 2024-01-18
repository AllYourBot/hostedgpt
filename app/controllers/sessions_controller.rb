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
      redirect_to post_login_destination, notice: "Successfully logged in."
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    Current.user = nil
    redirect_to login_path, notice: "Successfully logged out."
  end

  private
  def post_login_destination
    conversation = @user.assistants.first&.conversations&.first

    if conversation
      conversation_path conversation
    else
      dashboard_path
    end
  end
end
