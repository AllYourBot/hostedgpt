class Authentications::MicrosoftGraphOauthController < ApplicationController
  allow_unauthenticated_access

  # GET /auth/microsoft_graph/callback
  def create
    if Current.user
      Current.user.microsoft_graph_credential&.destroy
      _, cred = add_person_credentials("MicrosoftGraphCredential")
      cred.save! && redirect_to(edit_settings_person_path, notice: "Saved") && return

    elsif (credential = MicrosoftGraphCredential.find_by(oauth_id: auth[:uid]))
      @person = credential.user.person

    elsif Feature.disabled?(:registration)
      redirect_to(root_path, alert: "Registration is disabled") && return

    elsif auth_email && (user = Person.find_by(email: auth_email)&.user)
      @person = init_for_user(user)

    elsif auth_email && (@person = Person.find_by(email: auth_email))
      @person = init_for_person(@person)

    else
      @person = initialize_microsoft_person
    end

    if @person&.save
      login_as(@person, credential: @person.user.reload.microsoft_graph_credential)
      redirect_to root_path
    else
      @person&.errors&.delete :personable
      msg = @person.errors.full_messages.map { |m| m.gsub(/Personable |credentials /, "") }.to_sentence.capitalize
      if msg.downcase.include?("oauth refresh token can't be blank")
        msg += " " + helpers.link_to("Microsoft third-party connections", "https://account.microsoft.com/privacy/app-access", class: "underline") + " search for website, and delete all it's connections. Then try again."
      end

      redirect_to new_user_path, alert: msg
    end
  rescue => e
    warn e.message
    warn e.backtrace.join("\n")
    redirect_to edit_settings_person_path, alert: "Error. #{e.message}", status: :see_other
  end

  private

  def auth
    request.env["omniauth.auth"]&.deep_symbolize_keys || {}
  end

  def auth_email
    auth.dig(:info, :email)
  end

  def init_for_user(user)
    user.microsoft_graph_credential&.destroy

    user.first_name = auth[:info][:first_name]
    user.last_name = auth[:info][:last_name]
    @person = user.person
    add_person_credentials("MicrosoftGraphCredential").first
  end

  def init_for_person(person)
    @person.personable_type = "User"
    @person.personable_attributes = {
      first_name: auth[:info][:first_name],
      last_name: auth[:info][:last_name]
    }
    add_person_credentials("MicrosoftGraphCredential").first
  end

  def initialize_microsoft_person
    @person = Person.new({
    personable_type: "User",
      email: auth_email,
      personable_attributes: {
        first_name: auth[:info][:first_name],
        last_name: auth[:info][:last_name],
      }
    })
    add_person_credentials("MicrosoftGraphCredential").first
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
