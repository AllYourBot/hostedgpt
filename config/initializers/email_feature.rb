module Email
  class Providers
    POSTMARK = "postmark".freeze

    class << self
      def all
        constants.map { |c| const_get(c) }
      end
    end
  end
  Providers.freeze

  class PasswordReset
    TOKEN_TTL = 30.minutes.freeze
    TOKEN_PURPOSE = :password_reset.freeze
  end
  PasswordReset.freeze
end

Rails.application.configure do
  config.action_mailer.default_url_options = { host: Setting.email_host }

  if Feature.email?
    Setting.require_keys!(:email_provider, :email_from, :email_host)

    if Email::Providers.all.exclude?(Setting.email_provider)
      abort "ERROR: The value of EMAIL_PROVIDER must be one of: #{Email::Providers.all.join(", ")}"
    end

    if Setting.email_provider == Email::Providers::POSTMARK
      Setting.require_keys!(:postmark_server_api_token)

      config.action_mailer.delivery_method = :postmark
      config.action_mailer.postmark_settings = { api_token: Setting.postmark_server_api_token }
    end
  end
end
