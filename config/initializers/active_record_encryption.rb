# Commonly configured through config/credentials.yml.enc.
# For deployment to Render, we support configuration through ENV variables
if ENV['CONFIGURE_ACTIVE_RECORD_ENCRYPTION_FROM_ENV'] == 'true'
  Rails.application.configure do
    Rails.logger.info "Configuring active record encryption from environment"
    config.active_record.encryption.primary_key = ENV['ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY']
    config.active_record.encryption.deterministic_key = ENV['ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY']
    config.active_record.encryption.key_derivation_salt = ENV['ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT']
  end
end
