class GmailCredential < Credential
  has_one :active_authentication, -> { not_ended }, class_name: "Authentication", inverse_of: :credential

  def refresh_token
    properties.dig(:refresh_token)
  end
end
