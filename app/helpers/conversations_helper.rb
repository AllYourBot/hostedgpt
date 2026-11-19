module ConversationsHelper
  # Conversation.grouped_by_increasing_time_interval_for_user returns static English keys
  # ("Today", "Yesterday", ...) so its grouping logic stays stable regardless of locale;
  # translate them here for display.
  def translated_time_span(named_time_span)
    t("app.conversations.time_groups.#{named_time_span.parameterize(separator: '_')}")
  end

  # A bookmarked message shows its text, or a role label when content is blank — a streaming
  # or tool-call reply can carry no content_text, and a blank row would look broken (R7).
  def bookmarked_message_snippet(message)
    message.content_text.presence ||
      t("app.conversations.ui.message_no_content", name: from_name_for(message))
  end

  # The sidebar row and both /bookmarks entry types share the untitled-conversation fallback.
  def conversation_title_or_new_chat(conversation)
    conversation.title.presence || t("app.conversations.new_chat")
  end
end
