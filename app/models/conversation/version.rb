module Conversation::Version
  extend ActiveSupport::Concern

  def latest_message
    raise "would have returned #{msg&.id} - Change to latest_message_for_version"
  end

  def latest_message_for_version(version = nil)
    messages.for_conversation_version(version).last
  end

  def latest_version_for_message_index(index)
    messages.where(index: index).maximum(:version)
  end
end
