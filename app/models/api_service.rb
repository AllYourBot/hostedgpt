class APIService < ApplicationRecord
  DRIVER_OPEN_AI = "OpenAI"
  DRIVER_ANTHROPIC = "Anthropic"

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

  def delete!
    update!(deleted_at: Time.now)
    language_models.each { |language_model| language_model.delete! }
  end
end
