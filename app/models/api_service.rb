class APIService < ApplicationRecord
  DRIVER_OPEN_AI = "OpenAI"
  DRIVER_ANTHROPIC = "Anthropic"

  URL_OPEN_AI = "https://api.openai.com/"
  URL_ANTHROPIC = "https://api.anthropic.com/"

  DRIVERS = [DRIVER_OPEN_AI, DRIVER_ANTHROPIC]

  belongs_to :user

  has_many :language_models, -> { not_deleted }

  validates :url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), if: -> { url.present? }
  validates :name, :url, presence: true
  validates :driver, inclusion: { in: DRIVERS }

  encrypts :token
  normalizes :url, with: -> url { url.strip }

  scope :ordered, -> { order(:name) }

  def ai_backend
    driver == 'Anthropic' ? AIBackend::Anthropic : AIBackend::OpenAI
  end

  # In general we don't know, but for some URLs we can tell
  def requires_token?
    [URL_OPEN_AI, URL_ANTHROPIC].include?(url)
  end

  def effective_token
    token.presence || default_llm_key
  end

  def default_llm_key
    return nil unless Feature.default_llm_keys?
    return Setting.default_openai_key if url == URL_OPEN_AI
    return Setting.default_anthropic_key if url == URL_ANTHROPIC
  end

  def delete!
    update!(deleted_at: Time.now)
    language_models.each { |language_model| language_model.delete! }
  end
end
