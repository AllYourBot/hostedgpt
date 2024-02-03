class AutotitleConversationJob < ApplicationJob
  queue_as :default

  def perform(conversation_id)
    conversation = Conversation.find(conversation_id)
    Current.user = conversation.user

    message = conversation.messages.sorted.first
    new_title = generate_title_for(message.content_text)
    conversation.update!(title: new_title)
  end


  private

  def generate_title_for(text)
    json_response = ChatCompletionAPI.get_next_response(system_message, [text], response_format: {type: 'json_object'})
    json_response['topic']
  end

  def system_message
    <<~END
      You extract a 2-4 word topic from text. I will give the text of a chat message that someone sent. You reply with the
      topic of this message, but summarize the topic in 2-4 words.

      Example:
      ```
      when a rails view is rendering a collection, within that collection I want to know if I'm rendering the first item
      of the collection so I can have a conditional to render it differently
      ```

      Your reply (always do JSON):
      ```
      { topic: "Rails render collection counter" }
      ```
    END
  end
end
