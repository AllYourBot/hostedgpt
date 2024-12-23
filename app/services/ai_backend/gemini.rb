class AIBackend::Gemini < AIBackend
  include Tools
  class ::Gemini::Errors::ConfigurationError < ::Gemini::Errors::GeminiError; end

  # Rails system tests don't seem to allow mocking because the server and the
  # test are in separate processes.
  #
  # In regular tests, mock this method or the TestClients::Gemini class to do
  # what you want instead.
  def self.client
    if Rails.env.test?
      ::TestClient::Gemini
    else
      ::Gemini
    end
  end

  def self.test_execute(url, token, api_name)
    Rails.logger.info "Connecting to Gemini API server at #{url} with access token of length #{token.to_s.length}"
    client = ::Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: token,
        version: "v1beta"
      },
      options: {
        model: api_name,
        server_sent_events: true
      }
    )

    client.generate_content({
      contents: { role: "user", parts: { text: "Hello!" }}
    }).dig("candidates", 0, "content", "parts", 0, "text")
  rescue ::Faraday::Error => e
    "Error: #{e.message}"
  end

  def initialize(user, assistant, conversation = nil, message = nil)
    super(user, assistant, conversation, message)
    begin
      raise configuration_error if assistant.api_service.requires_token? && assistant.api_service.effective_token.blank?
      Rails.logger.info "Connecting to Gemini API server at #{assistant.api_service.url} with access token of length #{assistant.api_service.effective_token.to_s.length}"
      @client = self.class.client.new(
        credentials: {
          service: "generative-language-api",
          api_key: assistant.api_service.effective_token,
          version: "v1beta"
        },
        options: {
          model: assistant.language_model.api_name,
          server_sent_events: true
        }
      )
    rescue ::Faraday::UnauthorizedError, ::Faraday::BadRequestError => e
      raise configuration_error
    end
  end

  def client_method_name
    :stream_generate_content
  end

  def configuration_error
    ::Gemini::Errors::ConfigurationError
  end

  def set_client_config(config)
    super(config)

    @client_config =  {
      contents: config[:messages],
      system_instruction: ( system_message(config[:instructions]) if @assistant.language_model.supports_system_message?)
    }.compact
  end

  def get_oneoff_message(instructions, messages, params = {})
    response = @client.generate_content({
      system_instruction: system_message(instructions),
      contents: { role: "user", parts: { text: messages.first }}, # TODO: could implement preceding_conversation_messages and call it here
      ** params
    })
    response.dig("candidates", 0, "content", "parts", 0, "text")
  end

  def stream_next_conversation_message(&chunk_handler)
    set_client_config(
      messages: preceding_conversation_messages,
      instructions: full_instructions,
    )

    begin
      if Rails.env.test?
        @client.send(client_method_name, @client_config).each do |intermediate_response|
          content_chunk = intermediate_response.dig("candidates",0,"content","parts",0,"text")
          yield content_chunk if content_chunk != nil
        end
      else
        response = @client.send(client_method_name, @client_config) do |intermediate_response, parsed, raw|
          content_chunk = intermediate_response.dig("candidates",0,"content","parts",0,"text")
          yield content_chunk if content_chunk != nil
        end
      end
    rescue ::Faraday::UnauthorizedError, ::Faraday::BadRequestError => e
      puts e.message
      raise configuration_error
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
