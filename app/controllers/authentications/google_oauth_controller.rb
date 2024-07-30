class Authentications::GoogleOauthController < ApplicationController
  allow_unauthenticated_access

  def create
    if    auth[:provider] == "gmail"           && Current.user
      Current.user.gmail_credential&.destroy
      _, cred = add_person_credentials("GmailCredential")
      raise "You did not check all the permission boxes. Try again." unless cred.has_permission? %w(userinfo.email gmail.modify)
      cred.save! && redirect_to(edit_settings_person_path, notice: "Saved") && return

    elsif auth[:provider] == "google_tasks"    && Current.user
      Current.user.google_tasks_credential&.destroy
      _, cred = add_person_credentials("GoogleTasksCredential")
      raise "You did not check all the permission boxes. Try again." unless cred.has_permission? %w(userinfo.email tasks)
      cred.save! && redirect_to(edit_settings_person_path, notice: "Saved") && return

    elsif auth[:provider] == "google"          && credential = GoogleCredential.find_by(oauth_id: auth[:uid])
      @person = credential.user.person

    elsif Feature.disabled?(:registration)
      redirect_to(root_path, alert: "Registration is disabled") && return

    elsif auth[:provider] == "google"          && user = Person.find_by(email: auth_email)&.user
      @person = init_for_user(user)

    elsif auth[:provider] == "google"          && @person = Person.find_by(email: auth_email)
      @person = init_for_person(@person)

    elsif auth[:provider] == "google"
      @person = initialize_google_person
    end

    if @person&.save
      login_as(@person, credential: @person.user.reload.google_credential)
      redirect_to root_path
    else
      @person&.errors&.delete :personable
      msg = @person.errors.full_messages.map { |m| m.gsub(/Personable |credentials /, "") }.to_sentence.capitalize
      msg += " Cannot try again until you remove this website as a \"Google third-party connection\"." if msg.downcase.include?("oauth refresh token can't be blank")
      redirect_to new_user_path, alert: msg
    end
  rescue => e
    redirect_to edit_settings_person_path, alert: "Error. #{e.message}", status: :see_other
  end

  def failure
    if Current.user
      redirect_to edit_settings_person_path, alert: "Cancelled", status: :see_other
    else
      redirect_to login_path
    end
  end

  private

  def auth
    request.env["omniauth.auth"]&.deep_symbolize_keys || {}
  end

  def auth_email
    auth.dig(:info, :email)
  end

  def init_for_user(user)
    user.google_credential.destroy if user.google_credential

    user.first_name = auth[:info][:first_name]
    user.last_name = auth[:info][:last_name]
    @person = user.person
    add_person_credentials("GoogleCredential").first
  end

  def init_for_person(person)
    @person.personable_type = "User"
    @person.personable_attributes = {
      first_name: auth[:info][:first_name],
      last_name: auth[:info][:last_name]
    }
    add_person_credentials("GoogleCredential").first
  end

  def initialize_google_person
    @person = Person.new({
    personable_type: "User",
      email: auth_email,
      personable_attributes: {
        first_name: auth[:info][:first_name],
        last_name: auth[:info][:last_name],
      }
    })
    add_person_credentials("GoogleCredential").first
  end

  def add_person_credentials(type)
    p = Current.person || @person
    c = p.user.credentials.build(
      type: type,
      oauth_id: auth[:uid],
      oauth_email: auth[:info][:email],
      oauth_token: auth[:credentials][:token],
      oauth_refresh_token: auth[:credentials][:refresh_token],
      properties: auth[:credentials].except(:token, :refresh_token)
    )
    [p, c]
  end
end
