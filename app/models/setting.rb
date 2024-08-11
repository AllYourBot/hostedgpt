# frozen_string_literal: true

class Setting
  class << self
    def settings
      Rails.application.config.options.settings
    end

    def method_missing(method_name, *arguments, &block)
      ActiveRecord::Type::ImmutableString.new.cast(
        settings.fetch(method_name.to_sym, nil)
      )
    end
  end
end
