
class AutotitleConversationJob < ApplicationJob
  class ConversationNotReady < StandardError; end
  retry_on ConversationNotReady

  queue_as :default

  def perform(conversation_id)
    @conversation = Conversation.find(conversation_id)
    return false if @conversation.assistant.api_service.requires_token? && @conversation.assistant.api_service.effective_token.blank?

    messages = @conversation.messages.ordered.limit(4)
    raise ConversationNotReady  if messages.empty?

    new_title = Current.set(user: @conversation.user) do
      generate_title_for(messages.map(&:content_text).join("\n"))
    end
    @conversation.update!(title: new_title)
  end

  private

  def generate_title_for(text)

    ai_backend = @conversation.assistant.api_service.ai_backend.new(@conversation.user, @conversation.assistant)

    if ai_backend.class == AIBackend::OpenAI || ai_backend.class == AIBackend::Anthropic
      response = ai_backend.get_oneoff_message(
        system_message,
        [text],
        response_format: { type: "json_object" }  # this causes problems for Groq even though it's supported: https://console.groq.com/docs/api-reference#chat-create
      )
      return JSON.parse(response)["topic"]
    elsif ai_backend.class == AIBackend::Gemini
      response = ai_backend.get_oneoff_message(
        system_message,
        [text],
        generation_config: { response_mime_type: "application/json" }
      )
      return JSON.parse(response)["topic"]
    else
      response = ai_backend.get_oneoff_message(
        system_message,
        [text]
      )
      return response.scan(/(?<=:)"(.+?)"/)&.flatten&.first&.strip
    end
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
