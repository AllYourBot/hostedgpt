class UsersController < ApplicationController
  include Accessible

  def new
    @person = Person.new
    @person.personable = User.new
  end

  def create
    @person = Person.new
    @person.personable_type = "User"
    @person.update person_params

    respond_to do |format|
      if @person.save
        reset_session
        login_as @person.user

        format.html {
          redirect_to conversation_path(@person.personable.conversations.first), notice: "Account was successfully created."
        }
        format.json { render :show, status: :created, location: @person.personable.conversations.first }
      else
        @person.errors.delete :personable
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
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
    params.require(:person).permit(:email, personable_attributes: :password)
  end

  def update_params
    params.require(:user).permit(:first_name, :last_name, :openai_key)
  end
end
