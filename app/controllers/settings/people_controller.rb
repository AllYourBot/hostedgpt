class Settings::PeopleController < Settings::ApplicationController
  before_action :check_personable_id, only: :update
  before_action :prune_revoked_google_credentials, only: :edit

  def edit
  end

  def update
    Current.person.update!(person_params)
    apply_backend_choices!
    redirect_to edit_settings_person_path, notice: I18n.t("app.flashes.assistants.saved"), status: :see_other
  rescue
    @person = Current.person
    render :edit, status: :unprocessable_content
  end

  private

  def person_params
    h = params.require(:person).permit(:email, personable_attributes: [
      :id, :first_name, :last_name, :password, :profile_picture, :remove_profile_picture,
      :dark_mode, preferences: [feature: [:use_ruby_llm]],
      credentials_attributes: [ :id, :type, :password ]
    ]).to_h

    if (prefs = h.dig("personable_attributes", "preferences")).present? && (user = Current.person.user)
      h["personable_attributes"]["preferences"] = user.preferences.deep_merge(prefs.deep_symbolize_keys)
    end

    format_and_strip_all_but_first_valid_credential(h)
  end

  def apply_backend_choices!
    choices = params.permit(person: { backend_choices: User::Features.derived_backend_names })
                   .dig(:person, :backend_choices)
    return if choices.blank?

    user = Current.person.reload.user   # merge against fresh state, not a stale session copy
    choices.each { |name, value| user.features[name.to_sym] = value.presence }
  end

  def check_personable_id
    personable_id = params[:person].try(:[], :personable_attributes).try(:[], :id)
    if personable_id.present? && personable_id.to_i != Current.person.personable_id
      return render :edit, status: :unauthorized
    end
  end

  def prune_revoked_google_credentials
    GoogleSDK.prune_revoked_credentials!(Current.user) if Feature.google_tools?
  end
end
