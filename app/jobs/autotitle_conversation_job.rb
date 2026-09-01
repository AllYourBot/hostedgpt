
class AutotitleConversationJob < ApplicationJob
  class ConversationNotReady < StandardError; end
  retry_on ConversationNotReady

  queue_as :default

  def perform(conversation_id)
    @conversation = Conversation.find(conversation_id)
    return true if @conversation.title.present?

    return false if @conversation.assistant.api_service.requires_token? && @conversation.assistant.api_service.effective_token.blank?

    messages = @conversation.messages.ordered.limit(4)
    raise ConversationNotReady  if messages.empty?

    response = Current.set(user: @conversation.user) do
      fetch_reply_for(messages.map(&:content_text).join("\n"))
    end

    topic = usable_topic(response)
    return true if topic.nil?

    @conversation.reload
    return true if @conversation.title.present?

    @conversation.update!(title: topic)
  rescue Faraday::Error,
         ::Timeout::Error,
         AIBackend::ConfigurationError => e
    Rails.logger.warn("[AutotitleConversationJob] Provider failure for conversation #{@conversation.id}: #{e.class}")
    true
  end

  private

  def fetch_reply_for(text)
    ai_backend = @conversation.assistant.api_service.ai_backend.new(@conversation.user, @conversation.assistant)

    ai_backend.get_oneoff_message(
      system_message,
      [text],
      json: true
    )
  end

  def usable_topic(response)
    if response.blank?
      Rails.logger.warn("[AutotitleConversationJob] Unusable reply for conversation #{@conversation.id}")
      return nil
    end

    document = JSON.parse(response)
    topic = document.is_a?(Hash) ? document["topic"] : nil

    if topic.is_a?(String) && topic.present?
      topic
    else
      Rails.logger.warn("[AutotitleConversationJob] Unusable reply for conversation #{@conversation.id}")
      nil
    end
  rescue JSON::ParserError, TypeError, NoMethodError => e
    Rails.logger.warn("[AutotitleConversationJob] Unusable reply for conversation #{@conversation.id}: #{e.class}")
    nil
  end

  def system_message
    <<~END
      You extract a 2-4 word topic from text. I will give the text of a chat. You reply with the topic of this chat,
      but summarize the topic in 2-4 words. Even though it's not a complete sentence, capitalize the first letter of
      the first word unless it's some odd anomaly like "iPhone". Make sure that your answer matches the language of
      the text of the chat tht I give you.

      Example:
      ```
      when a rails view is rendering a collection, within that collection I want to know if I'm rendering the first item
      of the collection so I can have a conditional to render it differently

      If your collection is named messages then you can use messages_count within the collection partial and check for
      messages_count == 0
      ```

      Your reply (always do JSON):
      ```
      { "topic": "Rails collection counter" }
      ```
    END
  end
end
