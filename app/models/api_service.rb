class APIService < ApplicationRecord
  DRIVERS = %w(OpenAI Anthropic)

  belongs_to :user

  has_many :language_models, -> { not_deleted }

  validates :url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), if: -> { url.present? }
  validates :name, :url, presence: true
  validates :driver, inclusion: { in: DRIVERS }

  encrypts :access_token
  normalizes :url, with: -> url { url.strip }

  scope :ordered, -> { order(:name) }

  def ai_backend
    driver == 'Anthropic' ? AIBackend::Anthropic : AIBackend::OpenAI
  end

  def destroy
    raise ActiveRecord::ReadOnlyError 'System model cannot be deleted' if user.blank?
    if user.destroy_in_progress?
      super
    else
      update!(deleted_at: Time.now)
      language_models.each { |language_model| language_model.destroy! }
    end
  end
end
