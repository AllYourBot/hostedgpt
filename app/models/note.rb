class Note < ApplicationRecord
  belongs_to :chat
  belongs_to :parent, class_name: "Note", optional: true
  has_many :replies, class_name: "Note", foreign_key: :parent_id, dependent: :destroy
end
