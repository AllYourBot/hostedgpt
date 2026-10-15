class Authentications::GoogleOauthController < ApplicationController
  include OauthPerson

  allow_unauthenticated_access

  def create
    if    auth[:provider] == "gmail"           && Current.user
      Current.user.gmail_credential&.destroy
      _, cred = add_person_credentials("GmailCredential")
      raise "You did not check all the permission boxes. Try again." unless cred.has_permission? %w(userinfo.email gmail.modify)
      cred.save! && redirect_to(edit_settings_person_path, notice: I18n.t("app.flashes.language_models.saved")) && return

    elsif auth[:provider] == "google_tasks"    && Current.user
      Current.user.google_tasks_credential&.destroy
      _, cred = add_person_credentials("GoogleTasksCredential")
      raise "You did not check all the permission boxes. Try again." unless cred.has_permission? %w(userinfo.email tasks)
      cred.save! && redirect_to(edit_settings_person_path, notice: I18n.t("app.flashes.language_models.saved")) && return

    elsif auth[:provider] == "google"          && credential = GoogleCredential.find_by(oauth_id: auth[:uid])
      @person = credential.user.person

    elsif Feature.disabled?(:registration)
      redirect_to(root_path, alert: I18n.t("app.flashes.auth.registration_disabled")) && return

    elsif auth[:provider] == "google"          && user = Person.find_by(email: auth_email)&.user
      @person = init_for_user(user)

    elsif auth[:provider] == "google"          && @person = Person.find_by(email: auth_email)
      @person = init_for_person(@person)

    elsif auth[:provider] == "google"
      @person = initialize_person
    end

    login_person_or_explain_failure
  rescue => e
    redirect_to edit_settings_person_path, alert: I18n.t("app.flashes.auth.error_prefix", message: e.message), status: :see_other
  end

  def failure
    if Current.user
      redirect_to edit_settings_person_path, alert: I18n.t("app.flashes.auth.cancelled"), status: :see_other
    else
      redirect_to login_path
    end
  end

  private

  def credential_type
    "GoogleCredential"
  end

  def third_party_connections
    ["Google third-party connections", "https://myaccount.google.com/connections"]
  end
end
