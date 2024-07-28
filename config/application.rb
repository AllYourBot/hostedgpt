require_relative "boot"

require "rails/all"

# future gems
require_relative "../lib/string"
require_relative "../lib/false_class"
require_relative "../lib/true_class"
require_relative "../lib/nil_class"
require_relative "../app/models/feature"
require_relative "../app/models/setting"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module HostedGPT
  class Application < Rails::Application
    config.options = config_for(:options)

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # To remove in 2025. This allows migration db/migrate/20240415134849_encrypt_keys.rb to encrypt existing plaintext keys
    config.active_record.encryption.support_unencrypted_data = true

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Central Time (US & Canada)"
    config.eager_load_paths << Rails.root.join("lib")

    # Active Storage
    if Feature.cloudflare_storage?
      config.active_storage.service = :cloudflare
    else
      config.active_storage.service = :database
    end

    # Password Reset
    if Feature.password_reset_email?
      Feature.require_any_enabled!([:email_sender_postmark], message: "\"PASSWORD_RESET_EMAIL_FEATURE\" requires an \"EMAIL_SENDER_*_FEATURE\" feature to be enabled")

      Setting.require_keys!(:email_from, :email_host)

      config.action_mailer.default_url_options = { host: Setting.email_host }
      config.password_reset_token_ttl = 30.minutes
      config.password_reset_token_purpose = :password_reset

      if Feature.email_sender_postmark?
        Setting.require_keys!(:postmark_server_api_token)

        config.action_mailer.delivery_method = :postmark
        config.action_mailer.postmark_settings = { api_token: Setting.postmark_server_api_token }
      end
    end

    config.to_prepare do # FIXME: Remove this hack after Rails PR merges in: https://github.com/rails/rails/pull/52421
      ActionCable::Channel::Base.include ActionCableBasePatch
    end
  end
end
