class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]

  def new
    @user = User.new
  end

  def create
    ActiveRecord::Base.transaction do
      @person = Person.new(email: user_params[:email])
      @user = User.new(password: user_params[:password], password_confirmation: user_params[:password_confirmation])
      @person.personable = @user

      if @person.save
        session[:user_id] = @user.id
        redirect_to projects_path, notice: "Account was successfully created."
      else
        render :new
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
