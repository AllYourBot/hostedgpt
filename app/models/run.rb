class Run < ApplicationRecord
  belongs_to :assistant
  belongs_to :conversation

  has_many :steps, dependent: :destroy
  has_one :message, dependent: :nullify

  enum status: %w[queued in_progress requires_action cancelling cancelled failed completed expired].index_by(&:to_sym)

  validates :status, :expired_at, :model, :instructions, presence: true
  validates :tools, :file_ids, presence: true, allow_blank: true
end
