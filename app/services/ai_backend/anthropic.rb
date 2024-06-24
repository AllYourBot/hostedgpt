class AIBackend::Anthropic < AIBackend
  # Rails system tests don't seem to allow mocking because the server and the
  # test are in separate processes.
  #
  # In regular tests, mock this method or the TestClient::Anthropic class to do
  # what you want instead.
  def self.client
    if Rails.env.test?
      ::TestClient::Anthropic
    else
      ::Anthropic::Client
    end
  end

  def initialize(user, assistant, conversation, message)
    super(user, assistant, conversation, message)
    raise ::Anthropic::ConfigurationError if user.preferred_anthropic_key.blank?
    begin
      @client = self.class.client.new(access_token: user.preferred_anthropic_key)
    rescue ::Faraday::UnauthorizedError => e
      raise ::Anthropic::ConfigurationError
    end
  end

  def get_next_chat_message(&chunk_received_handler)
    stream_response_text = ""

    response_handler = proc do |intermediate_response, bytesize|
      chunk = intermediate_response.dig("delta", "text")
      print chunk if Rails.env.development?
      if chunk
        stream_response_text += chunk
        yield chunk
      end
    rescue ::GetNextAIMessageJob::ResponseCancelled => e
      raise e
    rescue ::Faraday::UnauthorizedError => e
      raise ::Anthropic::ConfigurationError
    rescue => e
      puts "\nUnhandled error in AIBackend::Anthropic response handler: #{e.message}"
      puts e.backtrace
    end

    response_handler = nil unless block_given?
    response = nil

    begin
      response = @client.messages(
        model: @assistant.language_model.provider_name,
        system: full_instructions,
        messages: preceding_messages,
        parameters: {
          max_tokens: 2000, # we should really set this dynamically, based on the model, to the max
          stream: response_handler,
        }
      )
    rescue ::Faraday::UnauthorizedError => e
      raise ::Anthropic::ConfigurationError
    end

    response_text = if response.is_a?(Hash) && response.dig("content")
      response.dig("content", 0, "text")
    else
      response
    end

    if response_text.blank? && stream_response_text.blank?
      raise ::Faraday::ParsingError
    else
      response_text
    end
  end

  private

  def preceding_messages
    @conversation.messages.for_conversation_version(@message.version).where("messages.index < ?", @message.index).collect do |message|
      if @assistant.supports_images? && message.documents.present?

        content = [{ type: "text", text: message.content_text }]
        content += message.documents.collect do |document|
          { type: "image",
            source: {
              type: "base64",
              media_type: document.file.blob.content_type,
              data: document.file_base64(:large),
            }
          }
        end

        {
          role: message.role,
          content: content
        }
      else
        {
          role: message.role,
          content: message.content_text || ""
        }
      end
    end
  end
end
