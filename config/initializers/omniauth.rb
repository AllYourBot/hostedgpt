OmniAuth.config.on_failure = Proc.new do |env|
  Authentications::GoogleOauthController.action(:failure).call(env)
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, Setting.google_auth_client_id, Setting.google_auth_client_secret, {
    name: "google"
  }

  provider :google_oauth2, Setting.google_auth_client_id, Setting.google_auth_client_secret, {
    name: "gmail",
    scope: %|
      email
      https://www.googleapis.com/auth/gmail.modify
    |,
    # Permissions explained: https://stackoverflow.com/questions/19102557/google-oauth-scope-for-sending-mail
    include_granted_scopes: true
  }

  provider :google_oauth2, Setting.google_auth_client_id, Setting.google_auth_client_secret, {
    name: "google_tasks",
    scope: %|
      email
      https://www.googleapis.com/auth/tasks
    |,
    include_granted_scopes: true
  }

end
