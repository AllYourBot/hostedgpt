OmniAuth.config.on_failure = Proc.new do |env|
  [302, {"Location" => "/auth/failure", "Content-Type"=> "text/html"}, []]
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, Setting.google_auth_client_id, Setting.google_auth_client_secret, {
    name: 'google'
  }

  provider :google_oauth2, Setting.google_auth_client_id, Setting.google_auth_client_secret, {
    name: 'gmail',
    scope: %|
      email,
      https://www.googleapis.com/auth/gmail.labels,
      https://www.googleapis.com/auth/gmail.modify,

    |,
    #  https://www.googleapis.com/auth/gmail.settings.basic  Create filters
    #  https://www.googleapis.com/auth/gmail.insert,
    #  https://www.googleapis.com/auth/gmail.compose,
    #  https://www.googleapis.com/auth/gmail.send,
    include_granted_scopes: true
  }
end