class Google < SDK

  def self.reauthenticate_credential(credential)
    begin
      response = SDK::Post.new("https://oauth2.googleapis.com/token").headers(
        content_type: "application/x-www-form-urlencoded",
      ).params(
        client_id: Setting.google_auth_client_id,
        client_secret: Setting.google_auth_client_secret,
        refresh_token: credential.refresh_token,
        grant_type: "refresh_token"
      )
      credential.update!(properties: response, last_authenticated_at: Time.current)
      credential.authentications.active.update_all(ended_at: Time.current)
      credential.authentications.active.create!(user: credential.user, token: response.token)

      return true
    rescue => e
      binding.pry
      credential.destroy
      return false
    end
  end
end
