# OpenRouter speaks the OpenAI wire dialect, so it rides AIBackend::OpenAI and
# overrides only its Error contract and attribution headers. OpenRouter model
# IDs are namespaced (e.g. "openai/gpt-4o", "anthropic/claude-sonnet-4") and are
# treated as distinct rows from the native-provider models.
#
# @see AIBackend::Groq the precedent this follows
#
# @note built on the OpenAI-compatible surface (#433) because it was the
#   easiest path to start with: chat, streaming, and tools come through the
#   shared client with no new dependencies. OpenRouter-specific extras (model
#   fallback arrays, provider routing, per-generation cost stats, plugins) and
#   the open_router community gem are deliberately untaken.
# @todo reach for the open_router community gem or native OpenRouter parameters
#   only when a concrete need arrives outside OpenAI compatibility (fallback
#   chains, per-generation cost display)
class AIBackend::OpenRouter < AIBackend::OpenAI
  def self.key_error_message
    "(You need to enter a valid API key for OpenRouter to use its models. Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find OpenRouter Key instructions.)"
  end

  def self.billing_url
    "https://openrouter.ai/credits"
  end

  def initialize(user, assistant, conversation = nil, message = nil)
    super
    # OpenRouter attributes requests to this app for its rankings. The headers
    # are optional; TestClient::OpenAI mirrors add_headers so tests can assert them.
    @client.add_headers(
      "HTTP-Referer" => Rails.application.config.x.app_url.to_s,
      "X-Title" => Setting.product_name.to_s
    )
  end
end
