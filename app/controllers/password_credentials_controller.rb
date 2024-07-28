class PasswordCredentialsController < ApplicationController
  require_unauthenticated_access
  before_action :ensure_manual_login_allowed

  layout "public"

  def edit
    @user = find_signed_user(params[:token])
  end

  def update
    user = find_signed_user(params[:token])

    if user.password_credential&.update(update_params)
      redirect_to login_path, notice: "Your password was reset succesfully. Please sign in."
    else
      render "edit", alert: "There was an error resetting your password"
    end
  end

  private

  def find_signed_user(token)
    User.find_signed!(token, purpose: Rails.application.config.password_reset_token_purpose)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to login_path, alert: "Your token has expired. Please try again"
  end

  def update_params
    params.permit(:password)
  end
end
