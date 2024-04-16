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

    scope :latest_version_for_conversation, -> { for_conversation_version(:latest) }

    scope :for_conversation_version, ->(version) do
      version ||= :latest
      c_id = all.where_clause.send(:predicates).find { |p| p.left.name == "conversation_id" }&.right&.value
      raise "latest_version_for_conversation needs to be used on a conversation's messages" if c_id.nil?

      if version == :latest
        # Find the message which is the highest index for the highest version
        last_msg_for_version = Message.select(:index, :version).where(conversation_id: c_id).
          order(version: :desc).order(index: :desc).first
      else
        last_msg_for_version = Message.select(:index, :version).where(conversation_id: c_id).where("version <= ?", version).
          order(version: :desc).order(index: :desc).first
      end

      select("DISTINCT ON (index) *").
        select("MAX(index) OVER (PARTITION BY version) AS max_index_for_version").
        select("ROW_NUMBER() OVER (ORDER BY index ASC, version DESC) AS subq_position").
        order(:index).order(max_index_for_version: :desc).order(version: :desc).
        where("version <= ? AND index <= ?",
          (last_msg_for_version&.version || 1),
          (last_msg_for_version&.index || 0)
        )
    end
  end

  def full_version
    "#{index}.#{version}".to_f
  end

  private

  def set_next_conversation_index
    if index.present?
      versions = conversation.messages.where(index: index).pluck(:version).sort
      latest_msg = conversation.latest_message
      max_version = 1
      if latest_msg && index <= latest_msg.index
        max_version = [versions.last.to_i, latest_msg.version].max + 1
      elsif latest_msg && index > latest_msg.index
        max_version = conversation.latest_message&.version
      end

      self.version ||= max_version

      if index < 0
        errors.add(:index, "is invalid")
      elsif index > 0 && !conversation.messages.exists?(index: index-1)
        errors.add(:index, "cannot skip a number")
      else # index is
        if version < 0 || version > max_version
          errors.add(:version, "is invalid for this index")
        elsif conversation.messages.exists?(index: index, version: version)
          errors.add(:version, "already exists for this index")
        elsif versions.present? && version < versions.max && !conversation.messages.exists?(index: index-1, version: version)
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
end
