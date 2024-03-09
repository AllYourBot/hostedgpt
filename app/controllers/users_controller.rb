class UsersController < ApplicationController
  include Accessible

  def new
    @person = Person.new
    @person.personable = User.new
  end

  def create
    @person = Person.new(person_params)

    if @person.save
      reset_session
      login_as @person.user

      redirect_to root_path
    else
      @person.errors.delete :personable
      render :new, status: :unprocessable_entity
    end
  end

  private

  def person_params
    params.require(:person).permit(:email, :personable_type, personable_attributes: [
      :first_name, :last_name, :password
    ])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name)
  end
end
