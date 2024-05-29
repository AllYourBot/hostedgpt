module PostgresqlHelper
  extend ActiveSupport::Concern

  included do
    # Added this ActiveStorage configuration when implementing postgres-file storage
    setup do
      if ActiveStorage::Current.respond_to?(:url_options)
        ActiveStorage::Current.url_options = { host: 'example.com', protocol: 'https' }
      else
        ActiveStorage::Current.host = "https://example.com"
      end
    end

    teardown do
      ActiveStorage::Current.reset
    end
  end
end
