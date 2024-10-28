# Be sure to restart your server when you modify this file.

def filter_regexp(filter_key, exemptions = [])
  filter_key_pattern = Regexp.escape(filter_key.to_s)

  # Join the exemptions array into a pattern for negative look-ahead
  unless exemptions.empty?
    exemptions_pattern = exemptions.map { |exemption| Regexp.escape(exemption.to_s) }.join("|")
    pattern = "^(?!.*(?:#{exemptions_pattern})).*(#{filter_key_pattern}).*$"
  else
    pattern = ".*(#{filter_key_pattern}).*"
  end

  Regexp.new(pattern)
end

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw,
  :secret,
  :_key,
  :crypt,
  :salt,
  :certificate,
  :otp,
  :ssn,
  filter_regexp(:token, [:token_count, :token_cost, :token_total_count, :token_total_cost]),
]
