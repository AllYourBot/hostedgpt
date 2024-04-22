module Message::Version
  extend ActiveSupport::Concern

  # Scopes for retrieving all the messages in a conversation by latest version or a specific version. Plus,
  # a set of callbacks that let you create messages without having to explicitly set the message version or
  # index. But if explicitly set version and index then validations will check them.
  #
  # See conversations.yml :versioned for a visual
  included do
    attribute :versions, :string, default: ""

    before_validation :set_next_conversation_index_and_version, on: :create
    before_validation :set_default_version,                     on: :create

    validate :branched_and_version_both_set,      if: -> { branched? || branched_from_version.present? }, on: :create

    after_create :set_branched_on_other_message,  if: :branched?

    scope :latest_version_for_conversation, -> { for_conversation_version(:latest) }

    scope :for_conversation_version, ->(version) do
      version ||= :latest
      raise "for_conversation_version(version) takes a numerical version or :latest" if version != :latest && version.to_s.to_i.to_s != version.to_s
      c_id = all.where_clause.send(:predicates).find { |p| p.left.name == "conversation_id" }&.right&.value
      raise "latest_version_for_conversation needs to be used on a conversation's messages" if c_id.nil?

      if version.to_s == "latest"
        # Find the message which is the highest index for the highest version
        last_msg_for_version = Message.select(:index, :version).where(conversation_id: c_id).
          order(version: :desc).order(index: :desc).first
      else
        last_msg_for_version = Message.select(:index, :version).where(conversation_id: c_id).where("version <= ?", version).
          order(version: :desc).order(index: :desc).first
      end

      version = last_msg_for_version&.version || 1
      index = last_msg_for_version&.index || 0

      joins("LEFT JOIN messages mB ON mB.branched_from_version = messages.version AND mB.conversation_id = messages.conversation_id AND mB.version <= #{version}").
      joins("INNER JOIN messages mV ON mV.index = messages.index AND mV.conversation_id = messages.conversation_id").
        select("DISTINCT ON (index) messages.*").
        select("CASE WHEN mB.version IS NOT NULL THEN mB.version ELSE messages.version END as max_branched_to").
        select("CASE WHEN messages.branched THEN STRING_AGG(mV.version::text, ',') OVER (PARTITION BY messages.index,messages.version ORDER BY mV.version ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) ELSE null END AS versions").
        order("messages.index").order(max_branched_to: :desc).order("messages.version DESC").
        where("messages.index <= ? AND messages.version <= ?", index, version)
    end
  end

  def versions
    return [] if not_branched?
    super.to_s.split(",").map(&:to_i).uniq.sort
  end

  def full_version
    "#{index}.#{version}".to_f
  end

  private

  def set_next_conversation_index_and_version
    if index.present?
      versions = conversation.messages.where(index: index).pluck(:version).sort
      latest_msg = conversation.latest_message_for_version(:latest)
      max_version = 1
      if latest_msg
        if branched
          max_version = conversation.messages.maximum(:version) + 1
        else
          # didn't specify the version & didn't indicate branching so assume we're continuing the latest conversation
          max_version = conversation.latest_message_for_version(:latest)&.version
        end
      end

      self.version ||= max_version

      if index < 0
        errors.add(:index, "is invalid")
      elsif index > 0 && !conversation.messages.exists?(index: index-1)
        errors.add(:index, "cannot skip a number")
      elsif index > 0 && !branched && !conversation.messages.exists?(index: index-1, version: version)
        errors.add(:branched, "is false but index is not following an existing message")
      else
        if version < 0 || version > max_version
          errors.add(:version, "#{version} is invalid for this index")
        elsif conversation.messages.exists?(index: index, version: version)
          errors.add(:version, "#{version} already exists for this index")
        elsif versions.present? && version < versions.max && !conversation.messages.exists?(index: index-1, version: version)
          errors.add(:version, "#{version} is invalid for this index")
        end
      end
    else
      if index.blank? && version.present?
        errors.add(:version, "cannot be set without also setting index")
      end
      if index.blank? && version.blank?
        latest_msg = self.conversation.latest_message_for_version(:latest)
        self.index    = (latest_msg&.index   || -1) + 1
        self.version  =  latest_msg&.version || 1
      end
    end
  end

  def set_default_version
    self.version ||= 1
  end

  def branched_and_version_both_set
    errors.add(:branched, 'must be set when branched_from_version is specified') if not_branched?
    errors.add(:branched_from_version, 'must be set when branched is true') if branched_from_version.nil?
  end

  def set_branched_on_other_message
    conversation.messages.find_by(index: index, version: branched_from_version).update_columns(branched: true)
  end
end
