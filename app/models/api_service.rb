class APIService < ApplicationRecord
  URL_OPEN_AI = "https://api.openai.com/"
  URL_ANTHROPIC = "https://api.anthropic.com/"
  URL_GROQ = "https://api.groq.com/openai/v1/"

  belongs_to :user

  has_many :language_models, -> { not_deleted }

  enum driver: %w[ openai anthropic ].index_by(&:to_sym)

  validates :url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), if: -> { url.present? }
  validates :name, :url, presence: true

  normalizes :url, with: -> url { url.strip }
  encrypts :token

  before_save :soft_delete_language_models, if: -> { deleted_at && deleted_at_changed? && deleted_at_was.nil? }

  scope :ordered, -> { order(:name) }

  def ai_backend
    openai? ? AIBackend::OpenAI : AIBackend::Anthropic
  end

  def requires_token?
    [URL_OPEN_AI, URL_ANTHROPIC].include?(url) # other services may require it but we don't always know
  end

  def effective_token
    token.presence || default_llm_key
  end

  private

  def default_llm_key
    return nil unless Feature.default_llm_keys?
    return Setting.default_openai_key if url == URL_OPEN_AI
    return Setting.default_anthropic_key if url == URL_ANTHROPIC
    return Setting.default_groq_key if url == URL_GROQ
  end

  def soft_delete_language_models
    language_models.each { |language_model| language_model.deleted! }
  end
end
