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

  def self.chat_provider_identities
    AIBackend::Policy.chat_provider_identities
  end

  DIRECT_DRIVERS = %w[openai anthropic gemini].freeze

  def provider_identity
    return :groq if driver == "openai" && url == URL_GROQ
    return :openrouter if driver == "openai" && url == URL_OPENROUTER
    return driver.to_sym if DIRECT_DRIVERS.include?(driver)
  end

  # RubyLLM is the transport for every chat provider identity. An identity
  # it can't serve (brave, or a nil driver) yields nil, silently.
  def ai_backend
    AIBackend::RubyLLM.supports_identity?(provider_identity) ? AIBackend::RubyLLM : nil
  end

  # Error facts resolve through the identity's policy class, so a Groq
  # or OpenRouter conversation still speaks Groq's or
  # OpenRouter's copy and billing URL, never the generic ones.
  def key_error_message
    AIBackend::Policy.key_error_message_for(provider_identity)
  end

  def billing_url
    AIBackend::Policy.billing_url_for(provider_identity)
  end

  def provider_name
    AIBackend::Policy.for_identity(provider_identity)&.display_name || "AI"
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
