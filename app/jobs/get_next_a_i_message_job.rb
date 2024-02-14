class GetNextAIMessageJob < ApplicationJob
  def perform(conversation_id, assistant_id)
    puts "GetNextAIMessageJob.perform(#{conversation_id}, #{assistant_id})"

    @conversation = Conversation.find conversation_id
    @assistant = Assistant.find assistant_id

    @new_message = @conversation.messages.create! role: :assistant, content_text: "", assistant: @conversation.assistant
    @new_message.broadcast_append_to @conversation

    response = AIBackends::OpenAI.new(@conversation.user, @assistant, @conversation)
      .get_next_chat_message do |content_chunk|
        @new_message.content_text += content_chunk
        @new_message.broadcast_replace_to @new_message.conversation, locals: { scroll_into_view: true }
      end

    if @new_message.content_text.blank? # this shouldn't be needed b/c the += above will build up the response, but test
                                        # env just returns a response w/o streaming and maybe that will happen in prod
      @new_message.content_text = response.dig("choices", 0, "message", "content")
    end

    @new_message.save!
    puts "\nFinished GetNextAIMessageJob.perform(#{conversation_id}, #{assistant_id})"

  rescue => e
    puts "Error in GetNextAIMessageJob: #{e.inspect}"
    puts e.backtrace
  end
end
