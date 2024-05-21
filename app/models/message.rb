# == Schema Information
#
# Table name: messages
#
#  id                    :bigint           not null, primary key
#  branched              :boolean          default(FALSE), not null
#  branched_from_version :integer
#  cancelled_at          :datetime
#  content_text          :string
#  index                 :integer          not null
#  processed_at          :datetime
#  role                  :string           not null
#  version               :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  assistant_id          :bigint           not null
#  content_document_id   :bigint
#  conversation_id       :bigint           not null
#  run_id                :bigint
#
# Indexes
#
#  index_messages_on_assistant_id                           (assistant_id)
#  index_messages_on_content_document_id                    (content_document_id)
#  index_messages_on_conversation_id                        (conversation_id)
#  index_messages_on_conversation_id_and_index_and_version  (conversation_id,index,version) UNIQUE
#  index_messages_on_index                                  (index)
#  index_messages_on_run_id                                 (run_id)
#  index_messages_on_updated_at                             (updated_at)
#  index_messages_on_version                                (version)
#
# Foreign Keys
#
#  fk_rails_...  (assistant_id => assistants.id)
#  fk_rails_...  (content_document_id => documents.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (run_id => runs.id)
#

class Message < ApplicationRecord
  include DocumentImage, Version, Cancellable

  belongs_to :assistant
  belongs_to :conversation
  belongs_to :content_document, class_name: "Document", optional: true
  belongs_to :run, optional: true
  has_one :latest_assistant_message_for, class_name: "Conversation", foreign_key: :last_assistant_message_id, dependent: :nullify

  enum role: %w[user assistant].index_by(&:to_sym)

  delegate :user, to: :conversation

  attribute :role, default: :user

  before_validation :create_conversation, on: :create, if: -> { conversation.blank? }, prepend: true

  validates :role, presence: true
  validates :content_text, presence: true, unless: :assistant?
  validate  :validate_conversation,  if: -> { conversation.present? && Current.user }
  validate  :validate_assistant,     if: -> { assistant.present? && Current.user }

  after_create :start_assistant_reply, if: :user?
  after_create :set_last_assistant_message, if: :assistant?
  after_save :update_assistant_on_conversation, if: -> { assistant.present? && conversation.present? }

  scope :ordered, -> { latest_version_for_conversation }

  private

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
    m = conversation.messages.create!(
      assistant: assistant,
      role: :assistant,
      content_text: nil,
      version: version,
      index: index+1
    )
  end

  def set_last_assistant_message
    conversation.update!(last_assistant_message: self)
  end

  def update_assistant_on_conversation
    return if conversation.assistant == assistant
    conversation.update!(assistant: assistant)
  end
end
