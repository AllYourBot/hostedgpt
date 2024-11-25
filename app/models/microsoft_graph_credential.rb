class MicrosoftGraphCredential < Credential
  alias_attribute :oauth_id, :external_id

  validates :oauth_token, presence: true
  validates :oauth_refresh_token, presence: true
  validates :oauth_id, presence: true, uniqueness: true
  validates :oauth_email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :oauth_email, with: -> email { email.downcase.strip }

  # Use this method to retrieve the latest oauth_token.
  # Token will be automatically renewed as necessary
  def token
    renew_token! if expired?
    oauth_token
  end

  def expires_at
    Time.at(properties[:expires_at]) if properties[:expires_at]
  rescue
    nil
  end

  def expired?
    expires_at && expires_at < Time.current
  end

  def renew_token!
    new_token = current_token.refresh!
    update(
      oauth_token: new_token.token,
      oauth_refresh_token: new_token.refresh_token,
      properties: { expires_at: new_token.expires_at }
    )
  end

  private

  def current_token
    OAuth2::AccessToken.new(
      strategy.client,
      oauth_token,
      refresh_token: oauth_refresh_token
    )
  end

  def strategy
    client_id = Setting.microsoft_graph_auth_client_id
    client_secret = Setting.microsoft_graph_auth_client_secret
    OmniAuth::Strategies::MicrosoftGraph.new(nil, client_id, client_secret)
  end
end
