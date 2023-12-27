class Note < ApplicationRecord
  belongs_to :chat, touch: true
  belongs_to :parent, class_name: "Note", optional: true, touch: true
  has_many :replies, dependent: :destroy

  validates :content, presence: true

  broadcasts_refreshes

  def send_to_openai!
    ProcessNoteJob.perform_later(id)
  end
end
