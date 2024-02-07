class GetNextAiMessageJob < ApplicationJob
  def perform(conversation_id)
    puts "GetNextAiMessageJob.perform(#{conversation_id})"

    @conversation = Conversation.find conversation_id
    messages = @conversation.messages.sorted.map(&:for_openai)
    @new_message = @conversation.messages.create! role: :assistant, content_text: "", assistant: @conversation.assistant
    @new_message.broadcast_append_to @conversation

    response = OpenAI::Client.new(
      access_token: @conversation.user.openai_key,
    ).chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: messages,
        temperature: 0.8,
        stream: build_response_handler,
        n: 1
      }
    )

    @conversation.broadcast_refresh
    puts "Finished GetNextAiMessageJob.perform(#{conversation_id})"

  rescue => e
    puts "Error in GetNextAiMessageJob: #{e.inspect}"
    puts e.backtrace
  end

  def build_response_handler
    proc do |chunk, bytesize|
      new_content = chunk.dig("choices", 0, "delta", "content")

      if new_content
        print new_content if Rails.env.development?
        @new_message.content_text += new_content
        @new_message.broadcast_replace_to @new_message.conversation, locals: { scroll_into_view: true }
        @new_message.save!
      end
    rescue => e
      puts "Error in response handler: #{e.inspect}"
      puts e.backtrace
    end
  end
end
