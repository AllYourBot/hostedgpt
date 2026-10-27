module AIBackend::Policy
  # Strings, constantized lazily at call time. Adding a
  # provider: add its policy class and an entry in this map.
  POLICY_CLASSES = {
    openai: "AIBackend::Policy::OpenAI",
    anthropic: "AIBackend::Policy::Anthropic",
    groq: "AIBackend::Policy::Groq",
    openrouter: "AIBackend::Policy::OpenRouter",
    gemini: "AIBackend::Policy::Gemini",
  }.freeze

  class << self
    def for_identity(identity)
      POLICY_CLASSES[identity&.to_sym]&.constantize
    end

    def chat_provider_identities
      POLICY_CLASSES.keys
    end

    def key_error_message_for(identity)
      for_identity(identity)&.key_error_message || Base.key_error_message
    end

    def billing_url_for(identity)
      for_identity(identity)&.billing_url
    end
  end
end
