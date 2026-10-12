# Tool calls are pinned false until this app's tool loop is debugged against
# Groq. This is a deliberate hold, not a judgment on the provider.
class AIBackend::Policy::Groq < AIBackend::Policy::Base
  def self.key_error_message
    "(You need to enter a valid API key for Groq to use Llama. Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find Groq Key instructions.)"
  end

  def self.billing_url
    "https://console.groq.com/keys"
  end

  def self.supports_tools?
    false
  end
end
