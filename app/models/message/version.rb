module Message::Version
  extend ActiveSupport::Concern

  # Scopes for retrieving all the messages in a conversation by latest version or a specific version. Plus,
  # a set of callbacks that let you create messages without having to explicitly set the message version or
  # index. But if explicitly set version and index then validations will check them.
  #
  # See conversations.yml versioned for a visual
  included do
    before_validation :set_next_conversation_index, on: :create
    before_validation :set_default_version,         on: :create

    before_create     :clear_preexisting_version_of_conversation, if: :conversation

    scope :latest_version_for_conversation, -> { for_conversation_version(:latest) }

    scope :for_conversation_version, ->(v) do
      c_id = all.where_clause.send(:predicates).find { |p| p.left.name == "conversation_id" }&.right&.value
      raise "latest_version_for_conversation needs to be used on a conversation's messages" if c_id.nil?

      if v == :latest
        # Find the message which is the highest index for the highest version
        m = Message.select(:index, :version).where(conversation_id: c_id).
          order(version: :desc).order(index: :desc).first
      else
        m = Message.select(:index, :version).where(conversation_id: c_id).where("version <= ?", v).
          order(version: :desc).order(index: :desc).first
      end

      select("DISTINCT ON (index) *").
        select("ROW_NUMBER() OVER (ORDER BY index ASC, version DESC) AS subq_position").
        order(:index).order(version: :desc).
        where("index <= ? AND version <= ?",
          (m&.index || 0),
          (m&.version || 1),
        )
    end
  end

  def full_version
    "#{index}.#{version}".to_f
  end

  private

  def set_next_conversation_index
    if index.present?
      if index > 0 && !conversation.messages.exists?(index: index-1)
        errors.add(:index, "cannot skip a number")
      else # index is valid
        v = conversation.latest_version_for_message_index(index)
        if v && conversation.latest_message && v < conversation.latest_message.version
          v = conversation.latest_message&.version
        end
        v ||= conversation.latest_message&.version&.-1

        if version.blank?
          self.version = (v || 0) + 1
        elsif version != (v || 0) + 1
          errors.add(:version, "is invalid for this index")
        end
      end
    else
      if index.blank? && version.present?
        errors.add(:version, "cannot be set without also setting index")
      end
      if index.blank? && version.blank?
        latest_msg = self.conversation.latest_message
        self.index    = (latest_msg&.index   || -1) + 1
        self.version  =  latest_msg&.version || 1
      end
    end
  end

  def set_default_version
    self.version ||= 1
  end

  def clear_preexisting_version_of_conversation
    conversation.messages.where("version >= ?", version).where("index > ?", index).destroy_all
  end
end
