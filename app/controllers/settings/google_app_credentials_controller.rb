class Settings::GoogleAppCredentialsController < Settings::ApplicationController
  before_action :set_credential

  # Only forgets the connection in HostedGPT. Revoking the token at Google would also cut off the user's
  # other Google tools, because include_granted_scopes merges them all into one grant for this app.
  def destroy
    @credential.destroy!
    redirect_to edit_settings_person_path, notice: I18n.t("app.flashes.google_app_credentials.disconnected"), status: :see_other
  end

  private

  def set_credential
    @credential = Current.user.credentials.where(type: GoogleSDK::APP_CREDENTIAL_TYPES).find_by(id: params[:id])
    if @credential.nil?
      redirect_to edit_settings_person_path, alert: I18n.t("app.flashes.google_app_credentials.not_found"), status: :see_other
    end
  end
end
