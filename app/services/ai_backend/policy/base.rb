class AIBackend::Policy::Base
  def self.key_error_message
    "(There is a configuration error with this API Service. Maybe you have an invalid API key? " +
      "Click your Profile in the bottom left and then Settings and then **API Services**.)"
  end

  def self.billing_url = nil

  def self.supports_tools? = true

  # Tools the provider runs itself inside one response (RubyLLM's with_provider_tools).
  def self.provider_tools = []

  def self.display_name = name.demodulize

  def self.attribution_headers = {}
end
