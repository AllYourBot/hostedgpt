class GetNextAIMessageJob < ApplicationJob
  class ResponseCancelled < StandardError; end

  def ai_backend
    if @assistant.model.starts_with?('gpt-')
      AIBackends::OpenAI
    else
      AIBackends::Anthropic
    end
  end

  def perform(message_id, assistant_id)
    puts "GetNextAIMessageJob.perform(#{message_id}, #{assistant_id})" if Rails.env.development?

    @message = Message.find_by(id: message_id)
    @conversation = @message.conversation
    @assistant = Assistant.find_by(id: assistant_id)

    return false if generation_was_cancelled? || message_is_populated?

    last_sent_at = Time.current

    response = ai_backend.new(@conversation.user, @assistant, @conversation, @message)
      .get_next_chat_message do |content_chunk|
        @message.content_text += content_chunk

        if Time.current.to_f - last_sent_at.to_f >= 0.1
          GetNextAIMessageJob.broadcast_updated_message(@message, thinking: true)
          last_sent_at = Time.current
        end

        if generation_was_cancelled?
          raise ResponseCancelled
        end
      end

    # TODO: With an invalid API key, anthropic is not throwing an exception and it's ending up here with an empty response

    if @message.content_text.blank? # this shouldn't be needed b/c the += above will build up the response, but test
                                    # env just returns a response w/o streaming and maybe that will happen in prod
      @message.content_text = response
    end

    wrap_up_the_message
    puts "\nFinished GetNextAIMessageJob.perform(#{message_id}, #{assistant_id})" if Rails.env.development?
    return true

  rescue ResponseCancelled => e
    puts "\nResponse cancelled" if Rails.env.development?
    wrap_up_the_message
    return true
  rescue OpenAI::ConfigurationError => e
    set_openai_error
    wrap_up_the_message
    return true
  rescue Anthropic::ConfigurationError => e
    set_anthropic_error
    wrap_up_the_message
    return true
  rescue Faraday::ConnectionFailed => e
    @message.content_text = "I experienced a connection error. #{e.message}"
    wrap_up_the_message
    return true
  rescue => e
    unless Rails.env.test?
      puts "\nError in GetNextAIMessageJob: #{e.inspect}"
      puts e.backtrace
    end
    return false # there may be some exceptions we want to re-raise?
  end

  def self.broadcast_updated_message(message, locals = {})
    message.broadcast_replace_to message.conversation, locals: {
      only_scroll_down_if_was_bottom: true,
      timestamp: (Time.current.to_f*1000).to_i
  }.merge(locals)
  end

  private

  def set_openai_error
    @message.content_text = "You need to enter a valid API key for OpenAI to use GPT-3.5 or GPT-4. Click your Profile in the bottom " +
      "left and then Settings. You will find OpenAI Key instructions."
  end

  def set_anthropic_error
    @message.content_text = "You need to enter a valid API key for Anthropic to use Claude. Click your Profile in the bottom " +
      "left and then Settings. You will find Anthropic Key instructions."
  end

  def wrap_up_the_message
    GetNextAIMessageJob.broadcast_updated_message(@message, thinking: false)
    @message.save!
    @message.conversation.touch # updated_at change will bump it up your list + ensures it will be auto-titled
  end

  def generation_was_cancelled?
    @message.cancelled? || (message_is_not_latest_in_conversation? && @message.not_rerequested?)
  end

  def message_is_populated?
    @message.content_text.present?
  end

  def message_is_not_latest_in_conversation?
    @message != @conversation.latest_message
  end
end
