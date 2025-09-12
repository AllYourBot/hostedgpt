class PasswordResetsController < ApplicationController
  allow_unauthenticated_access
  before_action :ensure_manual_login_allowed

  layout "public"

  def new
  end

  def create
    os = request.operating_system
    browser = request.browser
    SendResetPasswordEmailJob.perform_later(params[:email], os, browser) # queue as a job to avoid timing attacks

    redirect_to login_path, notice: I18n.t("app.flashes.password_resets.email_sent")
  end
end
