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
      login_as user.person, credential: user.password_credential
      redirect_to root_path, notice: "Your password was reset successfully."
    else
      render "edit", alert: "There was an error resetting your password"
    end
  end

  private

  def find_signed_user(token)
    User.find_signed!(token, purpose: Email::PasswordReset::TOKEN_PURPOSE)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to login_path, alert: "Your token has expired. Please try again."
  end

  def update_params
    params.permit(:password)
  end
end
