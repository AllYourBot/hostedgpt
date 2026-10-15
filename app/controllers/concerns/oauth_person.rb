module OauthPerson
  extend ActiveSupport::Concern

  private

  def credential_type
    raise NotImplementedError, "#{self.class} must name the credential it logs in with, e.g. \"GoogleCredential\""
  end

  def third_party_connections
    raise NotImplementedError, "#{self.class} must return [link text, url] for the page where a user revokes access"
  end

  def auth
    request.env["omniauth.auth"]&.deep_symbolize_keys || {}
  end

  def auth_email
    auth.dig(:info, :email)
  end

  def auth_name
    { first_name: auth[:info][:first_name], last_name: auth[:info][:last_name] }
  end

  def credential_association
    credential_type.underscore
  end

  def init_for_user(user)
    user.public_send(credential_association)&.destroy

    user.assign_attributes(auth_name)
    @person = user.person
    add_person_credentials(credential_type).first
  end

  def init_for_person(person)
    person.personable_type = "User"
    person.personable_attributes = auth_name
    add_person_credentials(credential_type).first
  end

  def initialize_person
    @person = Person.new(personable_type: "User", email: auth_email, personable_attributes: auth_name)
    add_person_credentials(credential_type).first
  end

  def add_person_credentials(type)
    p = Current.person || @person
    c = p.user.credentials.build(
      type:,
      oauth_id: auth[:uid],
      oauth_email: auth[:info][:email],
      oauth_token: auth[:credentials][:token],
      oauth_refresh_token: auth[:credentials][:refresh_token],
      properties: auth[:credentials].except(:token, :refresh_token)
    )
    [p, c]
  end

  def login_person_or_explain_failure
    if @person&.save
      login_as(@person, credential: @person.user.reload.public_send(credential_association))
      redirect_to root_path
    else
      redirect_to new_user_path, alert: person_errors_message
    end
  end

  def person_errors_message
    @person&.errors&.delete :personable
    msg = @person.errors.full_messages.map { |m| m.gsub(/Personable |credentials /, "") }.to_sentence.capitalize
    return msg unless msg.downcase.include?("oauth refresh token can't be blank")

    msg + " " + helpers.link_to(*third_party_connections, class: "underline") + " search for website, and delete all it's connections. Then try again."
  end
end
