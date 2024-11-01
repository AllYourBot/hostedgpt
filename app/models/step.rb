class Step < ApplicationRecord
  belongs_to :assistant
  belongs_to :conversation
  belongs_to :run

  enum :kind, %w[message_creation tool_calls].index_by(&:to_sym)
  enum :status, %w[in_progress cancelled failed completed expired].index_by(&:to_sym)

  validates :kind, :status, presence: true
  validates :details, presence: true, allow_blank: true
end
