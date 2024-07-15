namespace :db do
  desc "Setup database encryption and update credentials"
  task :setup_encryption, [:send_to_fly] => :environment do |t, args|
    args.with_defaults(send_to_fly: false)

    ensure_master_key unless ENV['RAILS_MASTER_KEY'].present?

    old_config = Rails.application.credentials.config
    config = old_config.deep_dup

    if config[:secret_key_base].nil? && ENV['SECRET_KEY_BASE'].nil?
      config = add_secret_key_base(config)
    end

    if config[:active_record_encryption].nil? && ENV['CONFIGURE_ACTIVE_RECORD_ENCRYPTION_FROM_ENV'] != 'true'
      config = add_active_record_encryption(config)
    end

    if config != old_config
      Rails.application.credentials.write(config.to_yaml)
      ActiveRecord::Encryption.config.primary_key = config[:active_record_encryption][:primary_key]
      ActiveRecord::Encryption.config.deterministic_key = config[:active_record_encryption][:deterministic_key]
      ActiveRecord::Encryption.config.key_derivation_salt = config[:active_record_encryption][:key_derivation_salt]
    end

    if args[:send_to_fly]
      # Implement the logic to send to Fly here
      puts "Sending configuration to Fly..."
      system("fly secrets set RAILS_MASTER_KEY=#{File.read(master_key_path)}")
      system("fly secrets set SECRET_KEY_BASE=#{config[:secret_key_base]}")
      system("fly secrets set CONFIGURE_ACTIVE_RECORD_ENCRYPTION_FROM_ENV=true")
      system("fly secrets set ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=#{ActiveRecord::Encryption.config.primary_key}")
      system("fly secrets set ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=#{ActiveRecord::Encryption.config.deterministic_key}")
      system("fly secrets set ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=#{ActiveRecord::Encryption.config.key_derivation_salt}")
    end

    puts "Done ensuring encryption is setup"
  end
end

Rake::Task["db:prepare"].enhance [:setup_encryption]

def add_secret_key_base(config)
  config[:secret_key_base] = SecureRandom.hex(64)
  config
end

def add_active_record_encryption(config)
  raise active_record_key_exception if Rails.env.production?

  config[:active_record_encryption] = {
    primary_key: SecureRandom.alphanumeric(32),
    deterministic_key: SecureRandom.alphanumeric(32),
    key_derivation_salt: SecureRandom.alphanumeric(32),
  }
  config
end

def encryption_init
  original_stdout = $stdout
  $stdout = StringIO.new
  Rake::Task["db:encryption:init"].invoke
  output = $stdout.string
  $stdout = original_stdout

  {
    primary_key: output.match(/primary_key: (\S+)/)[1],
    deterministic_key: output.match(/deterministic_key: (\S+)/)[1],
    key_derivation_salt: output.match(/key_derivation_salt: (\S+)/)[1],
  }
end

def ensure_master_key
  raise master_key_exception + active_record_key_exception if Rails.env.production?

  unless File.exist?(master_key_path)
    key = SecureRandom.hex(16)
    File.write(master_key_path, key)
  end
end

def master_key_path
  Rails.root.join('config', 'master.key')
end

def master_key_exception
  <<~END
    ###############################################################################################################
    ## ERROR: You are running in production but RAILS_MASTER_KEY is not set!
    ## If you are on Render go to: Dashboard > (your web service) > Environment > Add Environment Variable
    ##   Key: RAILS_MASTER_KEY
    ##   Value: (click 'Generate' on the right side of this field)
    ## REMEMBER to Save Changes
    ##
    ## If not on Render, create the ENV key on server and for the value: open rails console, run
    ## SecureRandom.base64(32) and copy & paste as the value for the key
    ###############################################################################################################
  END
end

def active_record_key_exception
  <<~END
    ###############################################################################################################
    ## ERROR: You are running in production but you are missing ActiveRecord encryption ENV keys!
    ## If you are on Render go to: Dashboard > (your web service) > Environment > Add Environment Variable
    ##   Key: CONFIGURE_ACTIVE_RECORD_ENCRYPTION_FROM_ENV
    ##     Value: true
    ##   Key: ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
    ##     Value: (click 'Generate' on the right side of this field)
    ##   Key: ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
    ##     Value: (click 'Generate' on the right side of this field)
    ##   Key: ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
    ##     Value: (click 'Generate' on the right side of this field)
    ##
    ## REMEMBER to Save Changes
    ##
    ## If not on Render, create the ENV keys on server and for the 3 generated values: open rails console, run
    ## SecureRandom.base64(32) three times (!) and copy & paste 3 unique values into your ENV keys.
    ###############################################################################################################
  END
end
