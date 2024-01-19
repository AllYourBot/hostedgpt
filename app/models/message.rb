class Message < ApplicationRecord
  belongs_to :conversation
  delegate :assistant, to: :conversation
  belongs_to :content_document, class_name: "Document", optional: true
  belongs_to :run, optional: true

  has_many :documents, dependent: :destroy

  enum role: %w[user assistant].index_by(&:to_sym)

  validates :run, presence: true, if: -> { assistant? }
  validates :role, presence: true

  after_create_commit -> {
    broadcast_append_to conversation, partial: "messages/message", locals: {scroll_into_view: true, conversation: conversation}
  }
end
