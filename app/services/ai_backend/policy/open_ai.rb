class AIBackend::Policy::OpenAI < AIBackend::Policy::Base
  def self.key_error_message
    "(You need to enter a valid API key for OpenAI to use GPT. Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find OpenAI Key instructions.)"
  end

  def self.billing_url
    "https://platform.openai.com/account/billing/overview"
  end
end
