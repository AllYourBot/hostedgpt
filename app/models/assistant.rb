class Assistant < ApplicationRecord
  MAX_LIST_DISPLAY = 5

  belongs_to :user

  has_many :conversations, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :runs, dependent: :destroy
  has_many :steps, dependent: :destroy
  has_many :messages, dependent: :destroy

  delegate :supports_images?, to: :language_model

  belongs_to :language_model
  belongs_to :api_service, optional: true

  validates :tools, presence: true, allow_blank: true
  validates :name, presence: true

  scope :ordered, -> { order(:id) }

  def initials
    return nil if name.blank?

    parts = name.split(/[\- ]/)

    parts[0][0].capitalize +
      parts[1]&.try(:[], 0)&.capitalize.to_s
  end

  def soft_delete
    return false if user.assistants.count <= 1
    update!(deleted_at: Time.now)
    return true
  end

  def soft_delete!
    raise "Can't delete user's last assistant" if !soft_delete
  end

  def ai_backend
    if api_service.present?
      api_service.ai_backend
    elsif language_model.name.starts_with?('gpt-')
      AIBackend::OpenAI
    else
      AIBackend::Anthropic
    end
  end

  def to_s
    name
  end
end
