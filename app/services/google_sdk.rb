class GoogleSDK < SDK
  APP_CREDENTIAL_TYPES = %w[GmailCredential GoogleTasksCredential]

  def self.reauthenticate_credential(credential)
    # from here: https://developers.google.com/identity/protocols/oauth2/web-server#exchange-authorization-code
    begin
      response = SDK::Post.new(url: "https://oauth2.googleapis.com/token").www_content.param(
        client_id: Setting.google_auth_client_id,
        client_secret: Setting.google_auth_client_secret,
        refresh_token: credential.oauth_refresh_token,
        grant_type: "refresh_token"
      )
      credential.update!(
        oauth_token: response.access_token,
        last_authenticated_at: Time.current,
        properties: response.to_h,
      )

      return true
    rescue => e
      credential.destroy if e.respond_to?(:status) && e.status == 400 && e.try(:body)&.dig("error_description")&.include?("Token has been expired")
      return false
    end
  end

  def self.prune_revoked_credentials!(user)
    user.credentials.where(type: APP_CREDENTIAL_TYPES).find_each do |credential|
      reauthenticate_credential(credential)
    end
  end
end
