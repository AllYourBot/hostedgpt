class Message < ApplicationRecord
  belongs_to :assistant
  belongs_to :conversation
  belongs_to :content_document, class_name: "Document", optional: true
  belongs_to :run, optional: true

  has_many :documents, dependent: :destroy

  enum role: %w[user assistant].index_by(&:to_sym)

  before_validation :set_default_role, on: :create
  before_validation :create_conversation, on: :create, if: -> { conversation.blank? }

  validates :content_text, :role, presence: true
  validates :run, presence: true, if: -> { assistant? }

  after_create_commit :broadcast_message


  private

  def create_conversation
    self.conversation = Conversation.create!(user: Current.user, assistant: assistant)
  end

  def set_default_role
    self.role ||= :user
  end

  def broadcast_message
    broadcast_append_to conversation, partial: "messages/message", locals: { scroll_into_view: true, conversation: conversation }
  end
end
