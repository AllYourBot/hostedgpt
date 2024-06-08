class GoogleCredential < Credential
  alias_attribute :oauth_id, :external_id

  validates :oauth_token, presence: true
  validates :oauth_refresh_token, presence: true
  validates :oauth_id, presence: true, uniqueness: true
  validates :oauth_email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :oauth_email, with: -> email { email.downcase.strip }
end
