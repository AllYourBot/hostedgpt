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
    config.load_defaults 7.2

  # I18n configuration
    config.i18n.available_locales = [:en, :de]
    config.i18n.default_locale = :en

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

    url_settings = [:app_url_protocol, :app_url_host]
    if url_settings.any?{|k| Setting.key_set?(k)}
      Setting.require_keys!(*url_settings)

      config.x.app_url_protocol = Setting.app_url_protocol
      config.x.app_url_host = Setting.app_url_host

      port = Setting.app_url_port.to_s
      if port.blank? || port == "80"
        config.x.app_url_port = nil
      else
        config.x.app_url_port = Setting.app_url_port
      end

      port_str = config.x.app_url_port.present? ? ":#{port}" : ""
      config.x.app_url = "#{Setting.app_url_protocol}://#{Setting.app_url_host}#{port_str}"
    else
      config.x.app_url = nil
    end

    # Active Storage
    if Feature.cloudflare_storage?
      config.active_storage.service = :cloudflare
    else
      config.active_storage.service = :database
    end

    config.to_prepare do # FIXME: Remove this hack after Rails PR merges in: https://github.com/rails/rails/pull/52421
      ActionCable::Channel::Base.include ActionCableBasePatch
    end
  end
end
