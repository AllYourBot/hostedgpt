class Note < ApplicationRecord
  belongs_to :chat, touch: true
  belongs_to :parent, class_name: "Note", optional: true
  has_many :replies, class_name: "Note", foreign_key: :parent_id, dependent: :destroy
  broadcasts_refreshes

  scope :no_replies, -> { where(parent_id: nil).includes(:replies) }
end
