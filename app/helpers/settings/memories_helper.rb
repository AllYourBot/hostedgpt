module Settings::MemoriesHelper
  def link_to_source(memory)
    message = memory.message

    "(" +
      link_to("source",
        conversation_messages_path(
            message.conversation_id,
            version: message.version,
            anchor: "message_#{message.id}"
          ),
        class: "underline"
    ) + ")"
  end
end
