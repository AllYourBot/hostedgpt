class AIBackend::Anthropic < AIBackend
  include Tools

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

  def self.test_execute(url, token, api_name)
    Rails.logger.info "Connecting to Anthropic API server at #{url} with access token of length #{token.to_s.length}"
    client = ::Anthropic::Client.new(
      uri_base: url,
      access_token: token
    )

    Rails.logger.info "Testing using model #{api_name}"
    client.messages(
      model: api_name,
      messages: [
        { "role": "user", "content": "Hello!" }
      ],
      system: "You are a helpful assistant.",
      parameters: { max_tokens: 1000 }
    ).dig("content", 0, "text")
  rescue => e
    "Error: #{e.message}"
  end

  def initialize(user, assistant, conversation = nil, message = nil)
    super(user, assistant, conversation, message)
    begin
      raise ::Anthropic::ConfigurationError if assistant.api_service.requires_token? && assistant.api_service.effective_token.blank?
      Rails.logger.info "Connecting to Anthropic API server at #{assistant.api_service.url} with access token of length #{assistant.api_service.effective_token.to_s.length}"
      @client = self.class.client.new(uri_base: assistant.api_service.url, access_token: assistant.api_service.effective_token)
    rescue ::Faraday::UnauthorizedError => e
      raise ::Anthropic::ConfigurationError
    end
  end

  private

  def client_method_name
    :messages
  end

  def configuration_error
    ::Anthropic::ConfigurationError
  end

  def set_client_config(config)
    super(config)

    @client_config = {
      model: @assistant.language_model.api_name,
      system: config[:instructions],
      messages: config[:messages],
      parameters: {
        max_tokens: 2000, # we should really set this dynamically, based on the model, to the max
        stream: config[:streaming] && @response_handler || nil,
      }.compact.merge(config[:params]&.except(:response_format) || {})
    }.compact
  end

  def stream_handler(&chunk_handler)
    proc do |intermediate_response, bytesize|
      chunk = intermediate_response.dig("delta", "text")

      if (input_tokens = intermediate_response.dig("message", "usage", "input_tokens"))
        # https://docs.anthropic.com/en/api/messages-streaming
        @message.input_token_count = input_tokens
      end
      if (output_tokens = intermediate_response.dig("usage", "output_tokens"))
        @message.output_token_count = output_tokens # no += because an early token count is partial, but the final one is the total
      end

      print chunk if Rails.env.development?
      if chunk
        @stream_response_text += chunk
        yield chunk
      end
    rescue ::GetNextAIMessageJob::ResponseCancelled => e
      raise e
    rescue ::Faraday::UnauthorizedError => e
      raise ::Anthropic::ConfigurationError
    rescue => e
      Rails.logger.info "\nUnhandled error in AIBackend::Anthropic response handler: #{e.message}"
      Rails.logger.info e.backtrace
    end
  end

  def preceding_conversation_messages
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
