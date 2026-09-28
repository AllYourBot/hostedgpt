class AIBackend::Anthropic < AIBackend
  include Tools

  CACHE_CONTROL = { type: "ephemeral" }.freeze

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
      parameters: {
        model: api_name,
        messages: [
          { "role": "user", "content": "Hello!" }
        ],
        system: "You are a helpful assistant.   You can generate an image based on what the user asks you to generate. You will pass the users prompt and will get back the image using the tool/function name. If your name is Claude, you should use the tool/function named generate_an_image.",
        max_tokens: 1000
      }
    ).dig("content", 0, "text")
  rescue => e
    "Error: #{e.message}"
  end

  def self.key_error_message
    "(You need to enter a valid API key for Anthropic to use Claude. Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find Anthropic Key instructions.)"
  end

  def self.billing_url
    "https://console.anthropic.com/settings/plans"
  end

  def initialize(user, assistant, conversation = nil, message = nil)
    super(user, assistant, conversation, message)
    begin
      raise AIBackend::ConfigurationError if assistant.api_service.requires_token? && assistant.api_service.effective_token.blank?
      Rails.logger.info "Connecting to Anthropic API server at #{assistant.api_service.url} with access token of length #{assistant.api_service.effective_token.to_s.length}"
      @client = self.class.client.new(uri_base: assistant.api_service.url, access_token: assistant.api_service.effective_token)
    rescue ::Anthropic::ConfigurationError
      # The gem raises its own class for a nil token when it falls back to its
      # configuration getter, which custom-URL services reach because they are
      # not in the requires_token? gate.
      raise AIBackend::ConfigurationError
    rescue ::Faraday::UnauthorizedError => e
      raise AIBackend::ConfigurationError
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

  def set_client_config(config)
    super(config)

    instructions = config[:instructions]
    if config[:json]
      # Mechanism-only coercion: the reply schema is the caller's job (the title
      # prompt already demonstrates it), so any future json-intent caller is not
      # handed autotitle vocabulary.
      instructions += "\n\nIMPORTANT: You must respond with ONLY valid JSON. Do not include any explanatory text, markdown formatting, or other content."
    end

    formatted_tools = @assistant.language_model.supports_tools? && anthropic_format_tools(Toolbox.tools) || nil
    system = config[:streaming] ? cached_system(instructions) : instructions

    @client_config = {
      model: @assistant.language_model.api_name,
      system:,
      messages: config[:messages],
      tools: formatted_tools,
      parameters: {
        model: @assistant.language_model.api_name,
        system:,
        messages: config[:messages],
        max_tokens: 2000, # we should really set this dynamically, based on the model, to the max
        stream: config[:streaming] && @response_handler || nil,
        tools: formatted_tools,
      }.compact.merge(config[:params]&.except(:response_format) || {})
    }.compact
  end

  # A conversation resends the same tools and instructions (memories, context files) every turn,
  # so cache them. One-off prompts are too short to be worth it.
  def cached_system(instructions)
    [{ type: "text", text: instructions, cache_control: CACHE_CONTROL }] if instructions.present?
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
      raise AIBackend::ConfigurationError
    rescue => e
      Rails.logger.info "\nUnhandled error in AIBackend::Anthropic response handler: #{e.message}"
    end
  end

  def preceding_conversation_messages
    history = conversation_history
    latest_user_message = latest_user_message(history)

    messages = history.collect do |message|
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
      elsif message.user?
        user_message(message, with_time: message == latest_user_message)
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

    add_cache_breakpoints(messages, history.index(latest_user_message))
  end

  def user_message(message, with_time:)
    content = [{ type: "text", text: message.content_text || "" }]
    content += message.documents.filter_map { |document| document_block(document) }
    content << { type: "text", text: current_time_note } if with_time

    { role: "user", content: content.one? ? content.first[:text] : content }
  end

  def document_block(document)
    if document.has_image?
      base64_block("image", document.file.blob.content_type, document.file_base64(:large)) if @assistant.supports_images?
    elsif document.has_document_pdf?
      return { type: "text", text: document.pdf_as_text } unless @assistant.supports_pdf?

      base64_block("document", "application/pdf", document.file_base64)
    end
  end

  def base64_block(type, media_type, data)
    { type:, source: { type: "base64", media_type:, data: } }
  end

  # A PDF or image is resent on every turn, so mark where the cacheable prefix ends: after the last
  # exchange before the newest user message (whose time note changes each turn), and after the newest
  # attachment so it is cached from the turn it arrives.
  def add_cache_breakpoints(messages, latest_user_index)
    return messages if latest_user_index.nil?

    cache_block(last_block_of(messages[latest_user_index - 1])) if latest_user_index.positive?
    cache_block(last_attachment_block_of(messages[latest_user_index]))
    messages
  end

  def last_attachment_block_of(message)
    Array(message[:content]).reverse.find { |block| block.is_a?(Hash) && block[:type].in?(%w[document image]) }
  end

  def last_block_of(message)
    message[:content] = [{ type: "text", text: message[:content] }] if message[:content].is_a?(String) && message[:content].present?
    message[:content].last if message[:content].is_a?(Array)
  end

  def cache_block(block)
    block[:cache_control] = CACHE_CONTROL if block
  end
end
