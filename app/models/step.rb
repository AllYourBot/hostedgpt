class Step < ApplicationRecord
  belongs_to :assistant
  belongs_to :conversation
  belongs_to :run

  enum :kind, [:message_creation, :tool_calls]
  enum :status, [:in_progress, :cancelled, :failed, :completed, :expired]

  validates :kind, :status, presence: true
  validates :details, presence: true, allow_blank: true
end
