Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    Setting.google_auth_client_id,
    Setting.google_auth_client_secret,
    name: 'google'
end
