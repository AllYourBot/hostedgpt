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
    @message.content_text ||= ""

    response = ai_backend.new(@conversation.user, @assistant, @conversation, @message)
      .get_next_chat_message do |content_chunk|
        @message.content_text += content_chunk

        if Time.current.to_f - last_sent_at.to_f >= 0.1
          GetNextAIMessageJob.broadcast_updated_message(@message, thinking: true)
          last_sent_at = Time.current
        end

        if generation_was_cancelled?
          @message.cancelled_at = Time.current
          raise ResponseCancelled
        end
      end

    if @message.content_text.blank? # this shouldn't happen b/c the += above will build up the response, but it's a final effort if things are blank
      @message.content_text = response if response.is_a?(String)
      raise Faraday::ParsingError if @message.content_text.blank?
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
  rescue Faraday::ParsingError => e
    set_response_error
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
    @message.content_text = "(You need to enter a valid API key for OpenAI to use GPT-3.5 or GPT-4. Click your Profile in the bottom " +
      "left and then Settings. You will find OpenAI Key instructions.)"
  end

  def set_anthropic_error
    @message.content_text = "(You need to enter a valid API key for Anthropic to use Claude. Click your Profile in the bottom " +
      "left and then Settings. You will find Anthropic Key instructions.)"
  end

  def set_response_error
    @message.content_text = "(Received a blank response. It's possible your API key is invalid, has expired, or the AI servers may be " +
      "experiencing trouble. Try again or ensure your API key is valid. You can change your API key by clicking your Profile in the bottom " +
      "left and then settings."
  end

  def wrap_up_the_message
    GetNextAIMessageJob.broadcast_updated_message(@message, thinking: false)
    @message.save!
    @message.conversation.touch # updated_at change will bump it up your list + ensures it will be auto-titled
  end

  def generation_was_cancelled?
    @cancel_counter = @cancel_counter.to_i + 1 # we want to skip redis on first cancel check to ensure test env runs does a second check

    message_cancelled? ||
      (newer_messages_in_conversation? && @message.not_rerequested?)
  end

  def message_cancelled?
    @message.cancelled? ||
      (@cancel_counter > 1 && @message.id == redis.get("message-cancelled-id")&.to_i)
  end

  def newer_messages_in_conversation?
    @message != @conversation.latest_message ||
      (@cancel_counter > 1 && @message.id != redis.get("conversation-#{@conversation.id}-latest_message-id")&.to_i)
  end

  def message_is_populated?
    @message.content_text.present?
  end

  def redis
    RedisConnection.client
  end
end
