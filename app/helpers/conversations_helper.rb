module ConversationsHelper
  # Conversation.grouped_by_increasing_time_interval_for_user returns static English keys
  # ("Today", "Yesterday", ...) so its grouping logic stays stable regardless of locale;
  # translate them here for display.
  def translated_time_span(named_time_span)
    t("app.conversations.time_groups.#{named_time_span.parameterize(separator: '_')}")
  end
end
