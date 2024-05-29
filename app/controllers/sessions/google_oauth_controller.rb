class Sessions::GoogleOauthController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    if auth[:provider] == "gmail"      && Current.user
      credential = Current.user.credentials.find_or_create_by(type: 'GmailCredential')
      credential.update!(email: auth[:info][:email], properties: auth[:credentials], last_authenticated_at: Time.current)
      credential.authentications.active.update_all(ended_at: Time.current)
      credential.authentications.active.create!(user: Current.user, token: auth[:credentials][:token])

      redirect_to edit_settings_person_path, notice: "Saved"
      return

    elsif auth[:provider] == "google"   && user = User.find_by(auth_uid: auth[:uid])
      login_as user
      redirect_to root_path # Successfully re-logged in as an existing google user
      return

    elsif Feature.disabled?(:registration)
      redirect_to root_path, alert: "Registration is disabled"
      return

    elsif auth[:provider] == "google"   && user = Person.find_by(email: auth_email)&.user
      user.auth_uid = auth[:uid]
      user.first_name = auth[:info][:first_name]
      user.last_name = auth[:info][:last_name]
      @person = user.person

    elsif auth[:provider] == "google"   && @person = Person.find_by(email: auth_email)
      @person.personable_type = "User"
      @person.personable_attributes = {
        auth_uid: auth[:uid],
        first_name: auth[:info][:first_name],
        last_name: auth[:info][:last_name]
      }

    elsif auth[:provider] == "google"
      @person = Person.new({
        personable_type: "User",
        email: auth[:info][:email],
        personable_attributes: {
          first_name: auth[:info][:first_name],
          last_name: auth[:info][:last_name],
          auth_uid: auth[:uid],
        }
      })
    end

    if @person&.save
      login_as @person.user
      redirect_to root_path # Successfully logged in after initializing a google oauth user
    else
      @person&.errors&.delete :personable
      redirect_to new_user_path, errors: @person&.errors&.full_messages
    end
  end

  def destroy
    if auth[:provider].in? addons
      redirect_to edit_settings_person_path, alert: "Cancelled"
    elsif auth[:provider] == "google"
      redirect_to root_url
    end
  end

  private

  def auth
    request.env['omniauth.auth']&.deep_symbolize_keys || {}
  end

  def auth_email
    auth.dig(:info, :email)
  end
end
