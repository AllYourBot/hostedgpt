class APIService < ApplicationRecord
  URL_OPEN_AI = "https://api.openai.com/v1/"
  URL_ANTHROPIC = "https://api.anthropic.com/"
  URL_GROQ = "https://api.groq.com/openai/v1/"
  URL_OPENROUTER = "https://openrouter.ai/api/v1/"
  URL_GEMINI = "https://generativelanguage.googleapis.com/v1beta/"
  URL_BRAVE = "https://api.search.brave.com/res/v1/"

  belongs_to :user

  has_many :language_models, -> { not_deleted }

  enum :driver, %w[openai anthropic gemini brave].index_by(&:to_sym)

  validates :url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), if: -> { url.present? }
  validates :name, :url, presence: true

  normalizes :url, with: -> url { url.strip }
  encrypts :token

  normalizes :token, with: -> token { token.strip }

  before_save :soft_delete_language_models, if: -> { deleted_at && deleted_at_changed? && deleted_at_was.nil? }

  scope :ordered, -> { order(:name) }

  # The per-provider backend registry: one identity -> one backend class that
  # owns that provider's wire dialect, error copy, and provider policy, whatever
  # transport (SDK or RubyLLM) ultimately serves the request. A service's
  # identity collapses the driver plus, for openai-dialect vendors, the
  # canonical URL into that one key: choices, RubyLLM support, and error facts
  # all resolve through it, never through the raw driver alone.
  #
  # Built as a method (not a class-body constant) so backend autoloading stays
  # as lazy as the dispatch it replaced. Adding a provider? Add its entry here
  # and map it in provider_identity. An unmapped driver yields a nil identity
  # and therefore nil backends, silently.
  def self.sdk_backends
    {
      openai: AIBackend::OpenAI,
      anthropic: AIBackend::Anthropic,
      groq: AIBackend::Groq,
      openrouter: AIBackend::OpenRouter,
      gemini: AIBackend::Gemini,
    }
  end

  def self.chat_provider_identities
    sdk_backends.keys
  end

  def self.identity_display_name(identity)
    sdk_backends[identity.to_sym]&.name&.demodulize || identity.to_s.humanize
  end

  DIRECT_DRIVERS = %w[openai anthropic gemini].freeze

  def provider_identity
    return :groq if driver == "openai" && url == URL_GROQ
    return :openrouter if driver == "openai" && url == URL_OPENROUTER
    return driver.to_sym if DIRECT_DRIVERS.include?(driver)
  end

  def sdk_backend
    self.class.sdk_backends[provider_identity]
  end

  def ai_backend
    use_ruby_llm? ? AIBackend::RubyLLM : sdk_backend
  end

  # An explicit per-identity choice ("ruby_llm" / "sdk") always wins; silent
  # users follow the site-wide flag, gated on RubyLLM actually supporting the
  # identity.
  def use_ruby_llm?
    identity = provider_identity
    return false unless AIBackend::RubyLLM.supports_identity?(identity)

    choice = user.features[User::Features.backend_choice_name(identity)]
    choice.present? ? choice == "ruby_llm" : Feature.use_ruby_llm?
  end

  # Error facts resolve through the identity's own backend class, so a Groq
  # or OpenRouter conversation served by RubyLLM still speaks Groq's or
  # OpenRouter's copy and billing URL, never the generic ones.
  def key_error_message
    sdk_backend&.key_error_message || AIBackend.key_error_message
  end

  def billing_url
    sdk_backend&.billing_url
  end

  def provider_name
    sdk_backend&.name&.demodulize || "AI"
  end

  def requires_token?
    [URL_OPEN_AI, URL_ANTHROPIC, URL_GEMINI, URL_BRAVE, URL_GROQ, URL_OPENROUTER].include?(url) # other services may require it but we don't always know
  end

  def logo_filename
    case url
    when URL_OPEN_AI then "openai_logo.svg"
    when URL_ANTHROPIC then "claude_logo.svg"
    when URL_GROQ then "groq_logo.svg"
    when URL_OPENROUTER then "openrouter_logo.png"
    when URL_GEMINI then "google_gemini_logo.svg"
    end
  end

  def effective_token
    token.presence || default_token
  end

  def test_api_service(url = nil, token = nil)
    backend = ai_backend
    return "Error: Testing is not supported for this API service." if backend.nil?
    backend.test_api_service(self, url, token)
  end

  private

  def default_token
    return Setting.default_brave_key if url == URL_BRAVE
    default_llm_key
  end

  def default_llm_key
    return nil unless Feature.default_llm_keys?
    return Setting.default_openai_key if url == URL_OPEN_AI
    return Setting.default_anthropic_key if url == URL_ANTHROPIC
    return Setting.default_groq_key if url == URL_GROQ
    return Setting.default_openrouter_key if url == URL_OPENROUTER
  end

  def soft_delete_language_models
    language_models.each { |language_model| language_model.deleted! }
  end
end
