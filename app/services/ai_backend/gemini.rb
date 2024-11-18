class AIBackend::Gemini < AIBackend
  include Tools

  # Rails system tests don't seem to allow mocking because the server and the
  # test are in separate processes.
  #
  # In regular tests, mock this method or the TestClients::Gemini class to do
  # what you want instead.
  def self.client
    if Rails.env.test?
      TestClient::Gemini
    else
      ::Gemini
    end
  end

  def initialize(user, assistant, conversation = nil, message = nil)
    super(user, assistant, conversation, message)
    begin
      raise ::OpenAI::ConfigurationError if assistant.api_service.requires_token? && assistant.api_service.effective_token.blank?
      Rails.logger.info "Connecting to Gemini API server at #{assistant.api_service.url} with access token of length #{assistant.api_service.effective_token.to_s.length}"
      @client = self.class.client.new(credentials: {service: "generative-language-api",
                                                    api_key: assistant.api_service.effective_token,
                                                    version: "v1beta"}, 
                                      options: { model: assistant.language_model.api_name, 
                                      server_sent_events: true })
    rescue ::Faraday::UnauthorizedError => e
      raise OpenAI::ConfigurationError
    end
  end

  def client_method_name
    :stream_generate_content
  end

  def configuration_error
    ::OpenAI::ConfigurationError
  end

  def set_client_config(config)
    super(config)

    @client_config = {
      contents: config[:messages],
      system_instruction: system_message(config[:instructions])      
    }
  end

  def get_oneoff_message(instructions, messages, params = {})
    set_client_config(
      messages: preceding_conversation_messages,
      instructions: full_instructions,
    )

    response = @client.send(client_method_name, @client_config)
    response.dig("candidates",0,"content","parts",0,"text")
  end

  def stream_next_conversation_message(&chunk_handler)
    set_client_config(
      messages: preceding_conversation_messages,
      instructions: full_instructions,
    )

    begin
      response = @client.send(client_method_name, @client_config) do |intermediate_response, parsed, raw|
        content_chunk = intermediate_response.dig("candidates",0,"content","parts",0,"text")
        yield content_chunk if content_chunk != nil
      end
    rescue ::Faraday::UnauthorizedError => e
      puts e.message
      raise OpenAI::ConfigurationError
    end
    return nil
  end

  private

  def system_message(content)
    return [] if content.blank?
    {
      role: "user", parts: { text: content }
    }
  end

  def preceding_conversation_messages
    @conversation.messages.for_conversation_version(@message.version).where("messages.index < ?", @message.index).collect do |message|
      if @assistant.supports_images? && message.documents.present?

        content = [{ text: message.content_text }]
        content += message.documents.collect do |document|
          { inline_data: {
              mime_type: document.file.blob.content_type,
              data: document.file_base64(:large),
            }
          }
        end

        {
          role: message.role == "assistant" ? "model" : "user", parts: content
        }
      else
        {
          role: message.role == "assistant" ? "model" : "user", parts: { text: message.content_text || "" }
        }
      end
    end
  end
end