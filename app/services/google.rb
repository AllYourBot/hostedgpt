class Google < SDK

  def self.reauthenticate_credential(credential)
    # from here: https://developers.google.com/identity/protocols/oauth2/web-server#exchange-authorization-code
    begin
      response = SDK::Post.new("https://oauth2.googleapis.com/token").header(
        content_type: "application/x-www-form-urlencoded",
      ).param(
        client_id: Setting.google_auth_client_id,
        client_secret: Setting.google_auth_client_secret,
        refresh_token: credential.refresh_token,
        grant_type: "refresh_token"
      )
      credential.update!(last_authenticated_at: Time.current)
      credential.authentications.active.update_all(ended_at: Time.current)
      credential.authentications.active.create!(user: credential.user, token: response.access_token)

      return true
    rescue => e
      credential.destroy
      return false
    end
  end
end
