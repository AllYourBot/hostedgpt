class AIBackend::Policy::OpenRouter < AIBackend::Policy::Base
  # OpenRouter attributes requests to this app in its rankings; these headers
  # ride on every chat built for the openrouter identity.
  def self.attribution_headers
    { "HTTP-Referer" => Rails.application.config.x.app_url.to_s, "X-Title" => Setting.product_name.to_s }
  end

  def self.key_error_message
    "(You need to enter a valid API key for OpenRouter to use its models. Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find OpenRouter Key instructions.)"
  end

  def self.billing_url
    "https://openrouter.ai/credits"
  end
end
