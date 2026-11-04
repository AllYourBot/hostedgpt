module HasConversationStarter
  extend ActiveSupport::Concern

  private

  def set_conversation_starters
    if @assistant.conversation_starters.any?
      @conversation_starters = @assistant.conversation_starters.map { [it, nil] }
      return
    end

    starters = I18n.t("app.conversations.starters")
    image_starters = I18n.t("app.conversations.image_starters")
  # Ensure we have an array of hashes with title/description
    starters = Array(starters).map { [it[:title] || it["title"], it[:description] || it["description"]] }.select { it[0].present? && it[1].present? }
    image_starters = Array(image_starters).map { [it[:title] || it["title"], it[:description] || it["description"]] }.select { it[0].present? && it[1].present? }

    @conversation_starters = starters.shuffle.take(3) + image_starters.shuffle.take(1)
  end
end
