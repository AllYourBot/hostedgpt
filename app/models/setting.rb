# frozen_string_literal: true

class Setting
  class << self
    def settings
      Rails.application.config.options.settings
    end

    def method_missing(method_name, *arguments, &block)
      if settings.keys.exclude?(method_name.to_sym)
        abort "ERROR: no setting found for #{method_name}. Please check settings in options.yml"
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

    def require_value_in!(key, values)
      if values.exclude?(send(key))
        abort "ERROR: The value of #{key.upcase} must be one of: #{values.join(", ")}"
      end
    end
  end
end
