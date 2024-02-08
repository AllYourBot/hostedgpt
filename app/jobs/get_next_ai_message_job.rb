class GetNextAiMessageJob < ApplicationJob
  def perform(conversation_id)
    puts "GetNextAiMessageJob.perform(#{conversation_id})"

    @conversation = Conversation.find conversation_id
    messages = @conversation.messages.sorted.map(&:for_openai)
    @new_message = @conversation.messages.create! role: :assistant, content_text: "", assistant: @conversation.assistant
    @new_message.broadcast_append_to @conversation

    response = AiBackends::OpenAi.new(@conversation.user.openai_key)
      .get_next_chat_message(messages) do |content_chunk|
        @new_message.content_text += content_chunk
        @new_message.broadcast_replace_to @new_message.conversation, locals: { scroll_into_view: true }
      end

    @new_message.save!
    puts "Finished GetNextAiMessageJob.perform(#{conversation_id})"

  rescue => e
    puts "Error in GetNextAiMessageJob: #{e.inspect}"
    puts e.backtrace
  end
end
