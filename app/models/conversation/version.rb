module Conversation::Version
  extend ActiveSupport::Concern

  def latest_message_for_version(version = nil) = messages.for_conversation_version(version).last

  def latest_version_for_message_index(index) = messages.where(index: index).maximum(:version)
end
