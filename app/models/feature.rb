# frozen_string_literal: true

class Feature
  class << self
    def configuration
      Rails.configuration.features
    end

    def enabled?(feature)
      ActiveModel::Type::Boolean.new.cast(
        configuration.fetch(feature&.to_sym, false)
      )
    end
  end
end
