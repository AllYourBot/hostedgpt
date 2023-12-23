class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :parent, class_name: "Message", optional: true
  has_many :replies, class_name: "Message", foreign_key: :parent_id, dependent: :destroy
end
