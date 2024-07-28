if Feature.email?
  Rails.application.configure do
    Setting.require_keys!(:email_sender, :email_from, :email_host)
    Setting.require_value_in!(:email_sender, ["postmark"])

    config.action_mailer.default_url_options = { host: Setting.email_host }

    if Setting.email_sender == "postmark"
      Setting.require_keys!(:postmark_server_api_token)

      config.action_mailer.delivery_method = :postmark
      config.action_mailer.postmark_settings = { api_token: Setting.postmark_server_api_token }
    end

    if Feature.password_reset_email?
      config.password_reset_token_ttl = 30.minutes
      config.password_reset_token_purpose = :password_reset
    end
  end
end
