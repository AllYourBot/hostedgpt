OmniAuth.config.on_failure = Proc.new do |env|
  [302, {"Location" => "/auth/failure", "Content-Type"=> "text/html"}, []]
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, Setting.google_client_id, Setting.google_client_secret, {
    name: 'google'
  }

  provider :google_oauth2, Setting.google_client_id, Setting.google_client_secret, {
    name: 'google_tasks',
    scope: %|
      email,
      https://www.googleapis.com/auth/tasks
    |,
    include_granted_scopes: true
  }

  provider :google_oauth2, Setting.google_client_id, Setting.google_client_secret, {
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

  provider :google_oauth2, Setting.google_client_id, Setting.google_client_secret, {
    name: 'google_calendar',
    scope: %|
      email,
      https://www.googleapis.com/auth/calendar.events,
    |,
    #  https://www.googleapis.com/auth/calendar.events.owned  See, create, change, and delete events on Google calendars you own
    #  https://www.googleapis.com/auth/calendar.calendars.readonly  See the title, description, default time zone, and other properties of Google calendars you have access to
    include_granted_scopes: true
  }
end