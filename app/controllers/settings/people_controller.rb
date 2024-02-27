class Settings::PeopleController < ApplicationController
  before_action :check_personable_id, only: :update

  def edit
  end

  def update
    if Current.person.update(person_params)
      redirect_to edit_settings_person_path, notice: "Person was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def person_params
    params.require(:person).permit(:email, personable_attributes: [:id, :first_name, :last_name, :password, :openai_key])
  end

  def check_personable_id
    if params[:person].try(:[], :personable_attributes).try(:[], :id)&.to_i != Current.person.personable_id
      return render :edit, status: :unauthorized
    end
  end
end