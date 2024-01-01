class Reply < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :note, touch: true
  has_one :chat, through: :note

  def self.for(note)
    find_by(note: note)
  end

  def broadcast_created
    broadcast_append_later_to(
      "#{dom_id(chat)}_notes",
      partial: "shared/reply",
      locals: {reply: self, scroll_to: true},
      target: "#{dom_id(chat)}_notes"
    )
  end

  def broadcast_updated
    # broadcast_append_to(
    #   "#{dom_id(note)}_content",
    #   partial: "shared/reply_content",
    #   locals: {message: self, scroll_to: true},
    #   target: "#{dom_id(note)}_content"
    # )
  end
end
