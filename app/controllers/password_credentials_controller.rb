class PasswordCredentialsController < ApplicationController
  allow_unauthenticated_access
  before_action :ensure_manual_login_allowed

  layout "public"

  def edit
    @user = find_signed_user(params[:token])
  end

  def update
    user = find_signed_user(params[:token])

    credential = user.credentials.find_or_initialize_by(type: "PasswordCredential")
    credential.password = update_params[:password]

    if credential.save
      logout_current if Current.client
      login_as user.person, credential: user.password_credential
      redirect_to root_path, notice: I18n.t("app.flashes.password_resets.reset_success")
    else
      render "edit", alert: I18n.t("app.flashes.password_resets.reset_error")
    end
  end

  private

  def find_signed_user(token)
    User.find_signed!(token, purpose: Email::PasswordReset::TOKEN_PURPOSE)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to login_path, alert: I18n.t("app.flashes.password_resets.token_expired")
  end

  def update_params
    params.permit(:password)
  end
end
