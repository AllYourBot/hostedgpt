class Memory < ApplicationRecord
  belongs_to :user
  belongs_to :message, optional: true
  belongs_to :assistant, optional: true # without one, every assistant shares the memory

  scope :for_assistant, ->(assistant) { where(assistant: [nil, assistant]) }

  validates :detail, presence: true
  validate :validate_assistant, if: :assistant

  private

  def validate_assistant
    errors.add(:assistant, "is invalid") unless assistant.user_id == user_id
  end
end
