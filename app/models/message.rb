class Message < ApplicationRecord
  belongs_to :assistant
  belongs_to :conversation, touch: true
  belongs_to :content_document, class_name: "Document", optional: true
  belongs_to :run, optional: true

  has_many :documents, dependent: :destroy

  enum role: %w[user assistant].index_by(&:to_sym)

  accepts_nested_attributes_for :documents

  before_validation :set_default_role, on: :create
  before_validation :create_conversation, on: :create, if: -> { conversation.blank? }

  validates :role, presence: true
  validates :content_text, presence: true, unless: :assistant?
  validate :validate_conversation_user, if: -> { conversation.present? && Current.user }

  scope :sorted, -> { order(:created_at) }

  after_create_commit :broadcast_message

  def for_openai
    {
      role: role,
      content: content_text
    }
  end

  private

  def create_conversation
    self.conversation = Conversation.create!(user: Current.user, assistant: assistant)
  end

  def set_default_role
    self.role ||= :user
  end

  def validate_conversation_user
    errors.add(:conversation, 'is invalid') unless conversation.user == Current.user
  end

  def broadcast_message
    broadcast_append_to conversation, partial: "messages/message", locals: { scroll_into_view: true }
  end
end
