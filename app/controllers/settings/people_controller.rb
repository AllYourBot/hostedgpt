class Settings::PeopleController < Settings::ApplicationController
  before_action :check_personable_id, only: :update

  def edit
  end

  def update
    Current.person.update!(person_params)
    redirect_to edit_settings_person_path, notice: "Saved", status: :see_other
  rescue
    @person = Current.person
    render :edit, status: :unprocessable_entity
  end

  private

  def person_params
    h = params.require(:person).permit(:email, personable_attributes: [
      :id, :first_name, :last_name, :password, :profile_picture, :remove_profile_picture, preferences: [:dark_mode],
      credentials_attributes: [ :id, :type, :password ]
    ]).to_h
    format_and_strip_all_but_first_valid_credential(h)
  end

  def check_personable_id
    personable_id = params[:person].try(:[], :personable_attributes).try(:[], :id)
    if personable_id.present? && personable_id.to_i != Current.person.personable_id
      return render :edit, status: :unauthorized
    end
  end
end
