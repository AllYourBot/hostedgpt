class GmailCredential < Credential
  def refresh_token
    properties.dig(:refresh_token)
  end
end
