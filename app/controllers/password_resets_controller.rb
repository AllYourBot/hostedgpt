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

    redirect_to '/login', notice: 'If an account with that email was found, we have sent a link to reset the password'
  end

  def edit
    @person = find_signed_person(params[:token])
  end

  def update
    @person = find_signed_person(params[:token])
    password_credential = @person&.personable&.password_credential

    if password_credential&.update(password_params)
      redirect_to '/login', notice: 'Your password was reset succesfully. Please sign in.'
    else
      render 'edit', alert: 'There was an error resetting your password'
    end
  end

  private

  def find_signed_person(token)
    Person.find_signed!(token, purpose: Rails.application.config.password_reset_token_purpose)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to '/login', alert: 'Your token has expired. Please try again'
  end

  def password_params
    h = params.require(:person).permit(personable_attributes: [
      credentials_attributes: [ :type, :password ]
    ]).to_h
    person_params = format_and_strip_all_but_first_valid_credential(h)
    { password: person_params[:personable_attributes][:credentials_attributes][0][:password] }
  end
end
