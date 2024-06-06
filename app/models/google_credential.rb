class GoogleCredential < Credential
  validates :external_id, presence: true, uniqueness: true, on: :create, if: -> { password_digest.blank? }
  validates :google_email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, if: -> { external_id.present? }

  normalizes :google_email, with: -> email { email.downcase.strip }

  def refresh_token
    properties.dig(:refresh_token)
  end
end
