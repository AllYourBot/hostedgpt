class Message < ApplicationRecord
  include DocumentImage, Version, Cancellable

  belongs_to :assistant
  belongs_to :conversation
  belongs_to :content_document, class_name: "Document", optional: true
  belongs_to :run, optional: true

  enum role: %w[user assistant].index_by(&:to_sym)

  delegate :user, to: :conversation

  before_validation :set_default_role, on: :create
  before_validation :create_conversation, on: :create, if: -> { conversation.blank? }, prepend: true

  validates :role, presence: true
  validates :content_text, presence: true, unless: :assistant?
  validate  :validate_conversation,  if: -> { conversation.present? && Current.user }
  validate  :validate_assistant,     if: -> { assistant.present? && Current.user }

  scope :ordered, -> { latest_version_for_conversation }

  after_create :start_assistant_reply, if: -> { user? }

  after_save :update_assistant_on_conversation, if: -> { assistant.present? && conversation.present? }

  private

  def set_default_role
    self.role ||= :user
  end

  def create_conversation
    self.conversation = Conversation.create!(user: Current.user, assistant: assistant)
  end

  def validate_conversation
    errors.add(:conversation, 'is invalid') unless conversation.user == Current.user
  end

  def validate_assistant
    errors.add(:assistant, 'is invalid') unless assistant.user == Current.user
  end

  def start_assistant_reply
    m = conversation.messages.create! role: :assistant, content_text: nil, assistant: assistant
    redis.set("conversation-#{conversation_id}-latest_message-id", m.id)
  end

  def update_assistant_on_conversation
    return if conversation.assistant == assistant
    conversation.update!(assistant: assistant)
  end
end
