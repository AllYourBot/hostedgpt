# The first Backend to inherit from another Backend. Groq speaks the OpenAI
# wire dialect, so it rides AIBackend::OpenAI and overrides only its Error
# contract and tools policy.
#
# @note tool calls are pinned false until this app's tool loop is debugged
#   against Groq. This is a deliberate hold, not a judgment on the provider.
# @todo elevate to its own driver (enum value + URL_GROQ row migration, the
#   AddBrave pattern) or its own client (community gems) once Groq needs
#   anything outside OpenAI compatibility
class AIBackend::Groq < AIBackend::OpenAI
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
