# frozen_string_literal: true

class Feature
  class << self
    def features
      Rails.application.config.options.features
    end

    def enabled?(feature)
      ActiveModel::Type::Boolean.new.cast(
        features.fetch(feature&.to_sym, false)
      )
    end

    def method_missing(method_name, *arguments, &block)
      if method_name.to_s.end_with?('?')
        enabled?(method_name.to_s.chomp('?'))
      else
        super
      end
    end
  end
end
