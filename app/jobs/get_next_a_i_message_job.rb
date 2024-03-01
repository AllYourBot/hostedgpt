class GetNextAIMessageJob < ApplicationJob
  class ResponseAborted < StandardError; end

  def perform(message_id, assistant_id)
    puts "GetNextAIMessageJob.perform(#{message_id}, #{assistant_id})" if Rails.env.development?

    @message = Message.find_by(id: message_id)
    @conversation = @message.conversation
    @assistant = Assistant.find_by(id: assistant_id)

    return false if user_has_replied_to_chat_since_queuing

    last_sent_at = Time.current

    response = AIBackends::OpenAI.new(@conversation.user, @assistant, @conversation)
      .get_next_chat_message do |content_chunk|
        @message.content_text += content_chunk

        if Time.current.to_f - last_sent_at.to_f >= 0.1
          GetNextAIMessageJob.broadcast_updated_message(@message)
          last_sent_at = Time.current
        end

        if @conversation.latest_message != @message
          raise ResponseAborted
        end
      end

    if @message.content_text.blank? # this shouldn't be needed b/c the += above will build up the response, but test
                                    # env just returns a response w/o streaming and maybe that will happen in prod
      @message.content_text = response.dig("choices", 0, "message", "content")
    end

    GetNextAIMessageJob.broadcast_updated_message(@message)
    @message.save!
    @message.conversation.touch # updated_at change will bump it up your list + ensures it will be auto-titled

    puts "\nFinished GetNextAIMessageJob.perform(#{message_id}, #{assistant_id})" if Rails.env.development?

    return true
  rescue ResponseAborted => e
    puts "\nResponse aborted" if Rails.env.development?
  rescue => e
    unless Rails.env.test?
      puts "\nError in GetNextAIMessageJob: #{e.inspect}"
      puts e.backtrace
    end
    return false # there may be some exceptions we want to re-raise?
  end

  def self.broadcast_updated_message(message)
    message.broadcast_replace_to message.conversation, locals: { only_scroll_down_if_was_bottom: true, timestamp: (Time.current.to_f*1000).to_i }
  end

  def user_has_replied_to_chat_since_queuing
    @message.user? || @message != @conversation.latest_message || @message.content_text.present?
  end
end
