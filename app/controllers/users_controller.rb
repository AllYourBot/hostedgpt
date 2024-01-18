class UsersController < ApplicationController
  include Accessible

  def new
    @user = User.new
    @person = Person.new
  end

  def create
    ActiveRecord::Base.transaction do
      @user = User.new user_params
      @person = Person.new person_params

      @person.personable = @user

      respond_to do |format|
        if @person.save
          reset_session
          login_as(@user)

          format.html { redirect_to dashboard_path, notice: "Account was successfully created." }
          format.json { render :show, status: :created, location: @user }
        else
          # The personable must be present, but the error is totally useless to a user
          @person.errors.delete(:personable)

          @errors = @person.errors.to_a
          @errors += @user.errors.to_a

          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
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
