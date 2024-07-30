class PasswordResetsController < ApplicationController
  require_unauthenticated_access
  before_action :ensure_manual_login_allowed

  layout "public"

  def new
  end

  def create
    os = request.operating_system
    browser = request.browser
    SendResetPasswordEmailJob.perform_later(params[:email], os, browser) # queue as a job to avoid timing attacks

    redirect_to login_path, notice: "If that email is valid, we just sent password reset email."
  end
end
