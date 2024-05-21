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

    def authenticate_with_password?
      return false if authenticate_with_http_header?

      enabled?(:password_authentication)
    end

    def authenticate_with_google?
      return false if authenticate_with_http_header?

      enabled?(:google_authentication)
    end

    def authenticate_with_http_header?
      enabled?(:http_header_authentication)
    end

    def authentication_http_header_name
      ActiveRecord::Type::ImmutableString.new.cast(
        configuration.fetch(:authentication_http_header_name, 'X-WEBAUTH-USER')
      )
    end

    def authentication_http_header_uid
      ActiveRecord::Type::ImmutableString.new.cast(
        configuration.fetch(:authentication_http_header_uid, 'X-WEBAUTH-NAME')
      )
    end

    def authentication_http_header_email
      ActiveRecord::Type::ImmutableString.new.cast(
        configuration.fetch(:authentication_http_header_email, 'X-WEBAUTH-EMAIL')
      )
    end

    def google_client_id
      ActiveRecord::Type::ImmutableString.new.cast(
        configuration.fetch(:google_client_id, nil)
      )
    end

    def google_client_secret
      ActiveRecord::Type::ImmutableString.new.cast(
        configuration.fetch(:google_client_secret, nil)
      )
    end
  end
end
