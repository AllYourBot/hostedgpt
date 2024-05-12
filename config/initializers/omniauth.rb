Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, Feature.google_client_id, Feature.google_client_secret,
    name: 'google'
end
