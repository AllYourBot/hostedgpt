# frozen_string_literal: true

class Feature
  class << self
    def raw_features
      Rails.application.config.options.features
    end

    def features_hash
      defined?(@@features_hash) && !@@features_hash.nil? ? @@features_hash : nil
    end

    def features_hash=(features)
      @@features_hash = features
    end

    def features
      return features_hash if features_hash
      @@features_hash = raw_features

      if @@features_hash[:http_header_authentication]
        @@features_hash[:password_authentication] = false
        @@features_hash[:google_authentication] = false
      end

      @@features_hash
    end

    def enabled?(feature)
      ActiveModel::Type::Boolean.new.cast(
        features.fetch(feature&.to_sym, false)
      )
    end

    def disabled?(feature)
      !enabled?(feature)
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
