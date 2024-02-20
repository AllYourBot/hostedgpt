class GetNextAIMessageJob < ApplicationJob
  def perform(conversation_id, assistant_id)
    puts "GetNextAIMessageJob.perform(#{conversation_id}, #{assistant_id})" if Rails.env.development?

    @conversation = Conversation.find conversation_id
    @assistant = Assistant.find assistant_id

    @new_message = @conversation.messages.create! role: :assistant, content_text: "", assistant: @conversation.assistant
    @new_message.broadcast_append_to @conversation, locals: { scroll_down: true }

    last_sent_at = Time.current.to_f

    response = AIBackends::OpenAI.new(@conversation.user, @assistant, @conversation)
      .get_next_chat_message do |content_chunk|
        @new_message.content_text += content_chunk

        if Time.current.to_f - last_sent_at > 0.5
          @new_message.broadcast_replace_to @new_message.conversation, locals: { only_scroll_down_if_was_bottom: true }
          last_sent_at = Time.current.to_f
        end
      end

    if @new_message.content_text.blank? # this shouldn't be needed b/c the += above will build up the response, but test
                                        # env just returns a response w/o streaming and maybe that will happen in prod
      @new_message.content_text = response.dig("choices", 0, "message", "content")
    end

    @new_message.broadcast_replace_to @new_message.conversation, locals: { only_scroll_down_if_was_bottom: true }
    @new_message.save!
    puts "\nFinished GetNextAIMessageJob.perform(#{conversation_id}, #{assistant_id})" if Rails.env.development?

  rescue => e
    puts "Error in GetNextAIMessageJob: #{e.inspect}"
    puts e.backtrace
  end
end
