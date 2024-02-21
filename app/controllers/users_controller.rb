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

  def update
    user = Current.user
    user.update(update_params)

    if user.save
      redirect_back fallback_location: "/", notice: "Account information saved.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def person_params
    params.require(:person).permit(:email, :personable_type, personable_attributes: :password)
  end

  def update_params
    params.require(:user).permit(:first_name, :last_name, :openai_key)
  end
end
