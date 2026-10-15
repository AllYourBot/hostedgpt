class Authentications::MicrosoftGraphOauthController < ApplicationController
  include OauthPerson

  allow_unauthenticated_access

  # GET /auth/microsoft_graph/callback
  def create
    if params[:error]
      if Current.user
        redirect_to(edit_settings_person_path, alert: params[:error_description])
      else
        redirect_to(login_path, alert: params[:error_description])
      end
      return
    end

    if Current.user
      Current.user.microsoft_graph_credential&.destroy
      _, cred = add_person_credentials("MicrosoftGraphCredential")
      cred.save! && redirect_to(edit_settings_person_path, notice: I18n.t("app.flashes.language_models.saved")) && return

    elsif (credential = MicrosoftGraphCredential.find_by(oauth_id: auth[:uid]))
      @person = credential.user.person

    elsif Feature.disabled?(:registration)
      redirect_to(root_path, alert: I18n.t("app.flashes.auth.registration_disabled")) && return

    elsif auth_email && (user = Person.find_by(email: auth_email)&.user)
      @person = init_for_user(user)

    elsif auth_email && (@person = Person.find_by(email: auth_email))
      @person = init_for_person(@person)

    else
      @person = initialize_person
    end

    login_person_or_explain_failure
  rescue => e
    warn e.message
    warn e.backtrace.join("\n")
    redirect_to edit_settings_person_path, alert: I18n.t("app.flashes.auth.error_prefix", message: e.message), status: :see_other
  end

  private

  def credential_type
    "MicrosoftGraphCredential"
  end

  def third_party_connections
    ["Microsoft third-party connections", "https://account.microsoft.com/privacy/app-access"]
  end
end
