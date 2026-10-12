class AIBackend::Policy::Anthropic < AIBackend::Policy::Base
  def self.key_error_message
    "(You need to enter a valid API key for Anthropic to use Claude. Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find Anthropic Key instructions.)"
  end

  def self.billing_url
    "https://console.anthropic.com/settings/plans"
  end
end
