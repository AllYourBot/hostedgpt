module Conversation::Version
  extend ActiveSupport::Concern

  def latest_message
    messages.latest_version_for_conversation.last
  end

  def latest_version_for_message_index(index)
    messages.where(index: index).maximum(:version)
  end
end
