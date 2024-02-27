class Settings::PeopleController < Settings::ApplicationController
  def edit
  end

  def update
    if Current.person.update(person_params)
      redirect_to edit_settings_person_path, notice: "Person was successfully updated.", status: :see_other
    else
      @person = Current.person
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def person_params
    params.require(:person).permit(:email, personable_attributes: [:id, :first_name, :last_name, :password, :openai_key])
  end
end
