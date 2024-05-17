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
  end
end
