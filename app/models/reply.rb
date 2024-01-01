class Reply < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :note, touch: true
  has_one :chat, through: :note

  def broadcast_created
    broadcast_append_later_to(
      "#{dom_id(chat)}_messages",
      partial: "shared/reply",
      locals: {message: self, scroll_to: true},
      target: "#{dom_id(chat)}_messages"
    )
  end

  def broadcast_updated
    broadcast_append_to(
      "#{dom_id(chat)}_messages",
      partial: "shared/reply",
      locals: {message: self, scroll_to: true},
      target: "#{dom_id(chat)}_messages"
    )
  end
end
