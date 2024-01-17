class UsersController < ApplicationController
  include Accessible

  def new
  end

  def create
    ActiveRecord::Base.transaction do
      @person = Person.new(email: user_params[:email])
      @user = User.new(password: user_params[:password], password_confirmation: user_params[:password])
      @person.personable = @user

      respond_to do |format|
        if @person.save
          reset_session
          login_as(@user)

          format.html { redirect_to dashboard_path, notice: "Account was successfully created." }
          format.json { render :show, status: :created, location: @user }
        else
          format.html { render :new }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def update
    Current.user.update!(update_params)
  end

  private

  def user_params
    params.require(:user).permit(:email, :password)
  end

  def update_params
    params.require(:user).permit(:first_name, :last_name, :openai_key)
  end
end
