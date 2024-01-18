class UsersController < ApplicationController
  include Accessible

  def new
    @user = User.new
    @person = Person.new
  end

  def create
    context = RegistrationContext.new params.permit(:email), params.permit(:password)

    respond_to do |format|
      if context.run
        reset_session
        login_as context.user

        format.html {
          redirect_to conversation_path(context.first_conversation), notice: "Account was successfully created."
        }
        format.json { render :show, status: :created, location: context.first_conversation }
      else
        @errors = context.errors

        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    Current.user.update!(update_params)
  end

  private

  def person_params
    params.permit(:email)
  end

  def user_params
    params.permit(:password)
  end

  def update_params
    params.require(:user).permit(:first_name, :last_name, :openai_key)
  end
end
