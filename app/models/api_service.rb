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

  def ai_backend
    if driver == "openai" && url == URL_GROQ
      AIBackend::Groq
    elsif driver == "openai" && url == URL_OPENROUTER
      AIBackend::OpenRouter
    elsif driver == "anthropic"
      AIBackend::Anthropic
    elsif driver == "gemini"
      AIBackend::Gemini
    elsif driver == "openai"
      AIBackend::OpenAI
    end
  end

  def requires_token?
    [URL_OPEN_AI, URL_ANTHROPIC, URL_GEMINI, URL_BRAVE, URL_GROQ, URL_OPENROUTER].include?(url) # other services may require it but we don't always know
  end

  def logo_filename
    case url
    when URL_OPEN_AI then "openai_logo.svg"
    when URL_ANTHROPIC then "claude_logo.svg"
    when URL_GEMINI then "google_gemini_logo.svg"
    end
  end

  def effective_token
    token.presence || default_token
  end

  def test_api_service(url = nil, token = nil)
    return "Error: Testing is not supported for this API service." if ai_backend.nil?
    ai_backend.test_api_service(self, url, token)
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
