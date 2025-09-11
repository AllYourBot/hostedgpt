module HasConversationStarter
  extend ActiveSupport::Concern

  private

  def set_conversation_starters
    starters = I18n.t("app.conversations.starters")
  # Ensure we have an array of hashes with title/description
    starters = Array(starters).map { |s| [s[:title] || s["title"], s[:description] || s["description"]] }.select { |a| a[0].present? && a[1].present? }
    @conversation_starters = starters.shuffle.take(4)
  end
end
