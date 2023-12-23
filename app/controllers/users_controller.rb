class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]

  def new
    if user_signed_in?
      redirect_to dashboard_path
    else
      render
    end
  end

  def create
    ActiveRecord::Base.transaction do
      @person = Person.new(email: user_params[:email])
      @user = User.new(password: user_params[:password], password_confirmation: user_params[:password])
      @person.personable = @user

      respond_to do |format|
        if @person.save
          reset_session
          session[:current_user_id] = @user.id
          format.html { redirect_to dashboard_path, notice: "Account was successfully created." }
          format.json { render :show, status: :created, location: @user }
        else
          format.html { render :new }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password)
  end
end
