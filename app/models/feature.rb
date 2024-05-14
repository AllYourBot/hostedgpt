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
      !(authenticate_with_google? || authenticate_with_http_header?)
    end

    def authenticate_with_google?
      authentication_approach == 'google'
    end

    def authenticate_with_http_header?
      authentication_approach == 'http_header'
    end

    def authentication_approach
      ActiveRecord::Type::ImmutableString.new.cast(
        configuration.fetch(:authentication_approach, 'password')
      )
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
