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
      system: "You are a helpful assistant.   You can generate an image based on what the user asks you to generate. You will pass the users prompt and will get back the image using the tool/function name. If your name is Claude, you should use the tool/function named generate_an_image.",
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

  def anthropic_format_tools(openai_tools)
    return [] if openai_tools.blank?

    openai_tools.map do |tool|
      function = tool[:function]
      {
        name: function[:name],
        description: function[:description],
        input_schema: {
          type: function.dig(:parameters, :type) || "object",
          properties: function.dig(:parameters, :properties) || {},
          required: function.dig(:parameters, :required) || []
        }
      }
    end
  rescue => e
    Rails.logger.info "Error formatting tools for Anthropic: #{e.message}"
    []
  end

  def handle_tool_use_streaming(intermediate_response)
    event_type = intermediate_response["type"]

    case event_type
    when "content_block_start"
      content_block = intermediate_response["content_block"]
      if content_block&.dig("type") == "tool_use"
        index = intermediate_response["index"] || 0
        Rails.logger.info "#### Starting tool_use block at index #{index}"
        @stream_response_tool_calls[index] = {
          "id" => content_block["id"],
          "name" => content_block["name"],
          "input" => {}
        }
      end
    when "content_block_delta"
      delta = intermediate_response["delta"]
      index = intermediate_response["index"] || 0

      if delta&.dig("type") == "input_json_delta"
        if @stream_response_tool_calls[index]
          partial_json = delta["partial_json"]
          @stream_response_tool_calls[index]["_partial_json"] ||= ""
          @stream_response_tool_calls[index]["_partial_json"] += partial_json

          begin
            @stream_response_tool_calls[index]["input"] = JSON.parse(@stream_response_tool_calls[index]["_partial_json"])
          rescue JSON::ParserError
            Rails.logger.info "#### JSON still incomplete, continuing to accumulate"
          end
        else
          Rails.logger.error "#### Received input_json_delta for index #{index} but no tool call initialized"
        end
      end
    when "content_block_stop"
      index = intermediate_response["index"] || 0
      if @stream_response_tool_calls[index]
        @stream_response_tool_calls[index].delete("_partial_json")
      end
    end

  rescue => e
    Rails.logger.error "Error handling Anthropic tool use streaming: #{e.message}"
  end

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
      tools: @assistant.language_model.supports_tools? && anthropic_format_tools(Toolbox.tools) || nil,
      parameters: {
        model: @assistant.language_model.api_name,
        system: config[:instructions],
        messages: config[:messages],
        max_tokens: 2000, # we should really set this dynamically, based on the model, to the max
        stream: config[:streaming] && @response_handler || nil,
        tools: @assistant.language_model.supports_tools? && anthropic_format_tools(Toolbox.tools) || nil,
      }.compact.merge(config[:params]&.except(:response_format) || {})
    }.compact
  end

  def stream_handler(&chunk_handler)
    proc do |intermediate_response, bytesize|
      chunk = intermediate_response.dig("delta", "text")
      tool_use_chunk = intermediate_response.dig("delta", "tool_use")

      handle_tool_use_streaming(intermediate_response)

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

      if tool_use_chunk
        @stream_response_tool_calls ||= []
        @stream_response_tool_calls << tool_use_chunk
      end
    rescue ::GetNextAIMessageJob::ResponseCancelled => e
      raise e
    rescue ::Faraday::UnauthorizedError => e
      raise ::Anthropic::ConfigurationError
    rescue => e
      Rails.logger.info "\nUnhandled error in AIBackend::Anthropic response handler: #{e.message}"
    end
  end

  def preceding_conversation_messages
    @conversation.messages.for_conversation_version(@message.version).where("messages.index < ?", @message.index).collect do |message|
      # Anthropic doesn't support "tool" role - convert tool messages to user messages with tool_result content
      if message.tool?
        {
          role: "user",
          content: [
            {
              type: "tool_result",
              tool_use_id: message.tool_call_id,
              content: message.content_text || ""
            }
          ]
        }
      elsif @assistant.supports_images? && message.documents.present?
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
      elsif message.assistant? && message.content_tool_calls.present?
        Rails.logger.info "#### Converting assistant message with tool calls"
        Rails.logger.info "#### Tool calls: #{message.content_tool_calls.inspect}"

        content = []

        if message.content_text.present?
          content << { type: "text", text: message.content_text }
        end

        message.content_tool_calls.each do |tool_call|
          arguments = tool_call.dig("function", "arguments") || tool_call.dig(:function, :arguments) || "{}"
          input = arguments.is_a?(String) ? JSON.parse(arguments) : arguments

          content << {
            type: "tool_use",
            id: tool_call["id"] || tool_call[:id],
            name: tool_call.dig("function", "name") || tool_call.dig(:function, :name),
            input: input
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
