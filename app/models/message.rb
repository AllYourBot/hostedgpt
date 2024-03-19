class Message < ApplicationRecord
  belongs_to :assistant
  belongs_to :conversation
  belongs_to :content_document, class_name: "Document", optional: true
  belongs_to :run, optional: true

  has_many :documents, dependent: :destroy

  enum role: %w[user assistant].index_by(&:to_sym)

  delegate :user, to: :conversation

  accepts_nested_attributes_for :documents

  before_validation :set_default_role, on: :create
  before_validation :create_conversation, on: :create, if: -> { conversation.blank? }

  validates :role, presence: true
  validates :content_text, presence: true, unless: :assistant?
  validate :validate_conversation_user, if: -> { conversation.present? && Current.user }

  scope :ordered, -> { order(:created_at) }

  after_create :start_assistant_reply, if: -> { user? }

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

  def start_assistant_reply
    conversation.messages.create! role: :assistant, content_text: "", assistant: conversation.assistant
  end
end
