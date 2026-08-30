class AIBackend::Gemini < AIBackend
  include Tools

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
        server_sent_events: false
      }
    )

    client.generate_content({
      contents: { role: "user", parts: { text: "Hello!" }}
    }).dig("candidates", 0, "content", "parts", 0, "text")
  rescue ::Faraday::Error => e
    "Error: #{e.message}"
  end

  def self.key_error_message
    "(There is a configuration error with the Gemini API Service. Maybe you have an invalid API key? " +
      "Click your Profile in the bottom left and then Settings and then **API Services**. You will find Gemini there.)"
  end

  def self.billing_url
    "https://aistudio.google.com/app/apikey"
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
    AIBackend::ConfigurationError
  end

  def set_client_config(config)
    super(config)

    @client_config =  {
      contents: config[:messages],
      system_instruction: ( system_message(config[:instructions]) if @assistant.language_model.supports_system_message?),
      tools: ( gemini_format_tools(Toolbox.tools) if @assistant.language_model.supports_tools? )
    }.compact
  end

  def get_oneoff_message(instructions, messages, params = {}, json: false)
    response = @client.generate_content({
      system_instruction: system_message(instructions),
      contents: { role: "user", parts: { text: messages.first }}, # TODO: could implement preceding_conversation_messages and call it here
      **(json ? { generation_config: { response_mime_type: "application/json" } } : {}),
      **params
    })
    response.dig("candidates", 0, "content", "parts", 0, "text")
  end

  def stream_next_conversation_message(&chunk_handler)
    @stream_response_text = ""
    @stream_response_tool_calls = []

    set_client_config(
      messages: preceding_conversation_messages,
      instructions: full_instructions,
    )

    begin
      if Rails.env.test?
        @client.send(client_method_name, @client_config).each do |intermediate_response|
          process_intermediate_response(intermediate_response, &chunk_handler)
        end
      else
        @client.send(client_method_name, @client_config) do |intermediate_response, parsed, raw|
          process_intermediate_response(intermediate_response, &chunk_handler)
        end
      end
    rescue ::Faraday::UnauthorizedError, ::Faraday::BadRequestError => e
      Rails.logger.error "Gemini rejected the request: #{e.try(:response)&.dig(:body) || e.message}"
      raise configuration_error
    end

    return format_parallel_tool_calls(@stream_response_tool_calls) if @stream_response_tool_calls.present?
    nil
  end

  private

  def process_intermediate_response(intermediate_response, &chunk_handler)
    parts = intermediate_response.dig("candidates", 0, "content", "parts")
    parts = [parts] if parts.is_a?(Hash)

    Array(parts).each do |part|
      if part["functionCall"].present?
        @stream_response_tool_calls << part # the whole part, because Gemini 3 hangs thoughtSignature off it
      elsif (text = part["text"])
        @stream_response_text += text
        chunk_handler&.call(text)
      end
    end
  end

  def system_message(content)
    return [] if content.blank?
    {
      role: "user", parts: { text: content }
    }
  end

  def preceding_conversation_messages
    @conversation.messages.for_conversation_version(@message.version).where("messages.index < ?", @message.index).collect do |message|
      if message.tool?
        tool_response_message(message)
      elsif message.assistant? && message.content_tool_calls.present?
        tool_call_message(message)
      elsif @assistant.supports_images? && message.documents.present? && message.role == "user"
        # Handle mixed content (images and PDFs)
        content = [{ text: message.content_text }]

        message.documents.each do |document|
          if document.has_image?
            content << { inline_data: {
                mime_type: document.file.blob.content_type,
                data: document.file_base64(:large),
              }
            }
          elsif document.has_document_pdf?
            # Extract text from PDF and include it in the conversation
            pdf_text = document.extract_pdf_text
            if pdf_text.present?
              content << {
                text: "\n\n[PDF Document: #{document.filename}]\n#{pdf_text}"
              }
            else
              content << {
                text: "\n[PDF Document: #{document.filename} - Unable to extract text from this PDF]"
              }
            end
          end
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

  def tool_call_message(message)
    parts = []
    parts << { text: message.content_text } if message.content_text.present?

    tool_calls = message.content_tool_calls
    tool_calls = [tool_calls] if tool_calls.is_a?(Hash)

    tool_calls.each do |tool_call|
      arguments = tool_call.dig("function", "arguments") || tool_call.dig(:function, :arguments) || {}
      args = arguments.is_a?(String) ? (JSON.parse(arguments) rescue {}) : arguments

      parts << {
        functionCall: {
          name: tool_call.dig("function", "name") || tool_call.dig(:function, :name),
          args: args
        },
        # Gemini 3 rejects a functionCall replayed without the signature it issued
        thoughtSignature: tool_call[:thought_signature] || tool_call["thought_signature"]
      }.compact
    end

    { role: "model", parts: parts }
  end

  # Gemini has no "tool" role; a tool result is a functionResponse part sent by
  # the user, and it's matched to the call by function name rather than by id.
  def tool_response_message(message)
    tool_call = message.content_tool_calls
    tool_call = tool_call.first if tool_call.is_a?(Array)
    tool_call = {} unless tool_call.is_a?(Hash)

    name = tool_call.dig("function", "name") || tool_call.dig(:function, :name) || message.tool_call_id
    content = JSON.parse(message.content_text.to_s) rescue message.content_text

    {
      role: "user",
      parts: [{
        functionResponse: {
          name: name,
          response: { name: name, content: content }
        }
      }]
    }
  end
end
