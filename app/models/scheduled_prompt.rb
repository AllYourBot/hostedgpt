class ScheduledPrompt < ApplicationRecord
  include Schedulable

  belongs_to :user
  belongs_to :assistant

  scope :ordered, -> { order(:created_at) }

  validates :prompt, :schedule, presence: true
  validate :assistant_belongs_to_user, if: -> { assistant.present? }

  def run!
    message = Current.set(user:) { assistant.messages.create!(content_text: prompt) }
    message.request_reply
    message
  end

  private

  def assistant_belongs_to_user
    errors.add(:assistant, "is invalid") unless assistant.user_id == user_id
  end
end
