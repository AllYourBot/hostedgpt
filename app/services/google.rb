class Google < SDK

  def reauthenticate_credential(credential)
    binding.pry
    response = SDK::Post.new("https://oauth2.googleapis.com/token").headers(
      content_type: "application/x-www-form-urlencoded",
    ).params(
      client_id: Setting.google_auth_client_id,
      client_secret: Setting.google_auth_client_secret,
      refresh_token: credential.refresh_token,
      grant_type: "refresh_token"
    )
    binding.pry
    credential.update!(properties: response, last_authenticated_at: Time.current)
    credential.authentications.active.update_all(ended_at: Time.current)
    credential.authentications.active.create!(user: credential.user, token: response.token)
  end
end
