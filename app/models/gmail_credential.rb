class GmailCredential < Credential
  has_one :active_authentication, -> { not_ended }, class_name: "Authentication", foreign_key: "credential_id"

  def refresh_token
    properties.dig(:refresh_token)
  end
end
