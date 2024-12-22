# frozen_string_literal: true

class Setting
  class << self
    def settings
      Rails.application.config.options.settings
    end

    def method_missing(method_name, *arguments, &block)
      if settings.keys.exclude?(method_name.to_sym)
        if ENV["RAILS_ENV"] == "test"
          abort
        else
          abort "ERROR: no setting found for #{method_name}. Please check settings in options.yml"
        end
      end

      ActiveRecord::Type::ImmutableString.new.cast(
        settings.fetch(method_name.to_sym, nil)
      )
    end

    def require_keys!(*keys)
      keys.each do |key|
        if send(key).blank?
          abort "ERROR: Please set the #{key.upcase} environment variable or secret" # if we're missing a required setting then fail fast and don't start the app
        end
      end
    end

    def key_set?(key)
      send(key).present?
    end
  end
end
