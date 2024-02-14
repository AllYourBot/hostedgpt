
class AutotitleConversationJob < ApplicationJob
  class ConverstionNotReady < StandardError; end
  retry_on ConverstionNotReady

  queue_as :default


  def perform(conversation_id)
    conversation = Conversation.find(conversation_id)
    Current.user = conversation.user

    messages = conversation.messages.ordered.limit(4)
    raise ConverstionNotReady  if messages.empty?

    new_title = generate_title_for(messages.map(&:content_text).join("\n"))
    conversation.update!(title: new_title)
  end


  private

  def generate_title_for(text)
    json_response = ChatCompletionAPI.get_next_response(system_message, [text], response_format: {type: 'json_object'})
    json_response['topic']
  end

  def system_message
    <<~END
      You extract a 2-4 word topic from text. I will give the text of a chat. You reply with the topic of this chat,
      but summarize the topic in 2-4 words. Even though it's not a complete sentence, capitalize the first letter of
      the first word unless it's some odd anomaly like "iPhone".

      Example:
      ```
      when a rails view is rendering a collection, within that collection I want to know if I'm rendering the first item
      of the collection so I can have a conditional to render it differently

      If your collection is named messages then you can use messages_count within the collection partial and check for
      messages_count == 0
      ```

      Your reply (always do JSON):
      ```
      { topic: "Rails collection counter" }
      ```
    END
  end
end
