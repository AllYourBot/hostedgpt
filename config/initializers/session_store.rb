Rails.application.config.session_store :cookie_store,
  key: "_hosted_session",
  expire_after: 20.years
