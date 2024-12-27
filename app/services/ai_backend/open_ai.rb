class AIBackend::OpenAI < AIBackend
  include Tools

  # Rails system tests don't seem to allow mocking because the server and the
  # test are in separate processes.
  #
  # In regular tests, mock this method or the TestClient::OpenAI class to do
  # what you want instead.
  def self.client
    if Rails.env.test?
      ::TestClient::OpenAI
    else
      ::OpenAI::Client
    end
  end

  def self.test_execute(url, token, api_name)
    if Rails.env.test?
      client = ::TestClient::OpenAI.new(
        access_token: token,
        uri_base: url
      )
      response = client.send(:chat, ** {parameters: {model: api_name, messages: [{ role: "user", content: "Hello!" }]}})
    else
      Rails.logger.info "Connecting to OpenAI API server at #{url} with access token of length #{token.to_s.length}"
      client = ::OpenAI::Client.new(
        access_token: token,
        uri_base: url
      )

      Rails.logger.info "Testing using model #{api_name}"
      response = client.chat(parameters: {model: api_name, messages: [{ role: "user", content: "Hello!" }]})
    end

    response.dig("choices", 0, "message", "content")
  rescue ::Faraday::Error => e
    "Error: #{e.message}"
  end

  def initialize(user, assistant, conversation = nil, message = nil)
    super(user, assistant, conversation, message)
    begin
      raise ::OpenAI::ConfigurationError if assistant.api_service.requires_token? && assistant.api_service.effective_token.blank?
      Rails.logger.info "Connecting to OpenAI API server at #{assistant.api_service.url} with access token of length #{assistant.api_service.effective_token.to_s.length}"
      @client = self.class.client.new(uri_base: assistant.api_service.url, access_token: assistant.api_service.effective_token, api_version: "")
    rescue ::Faraday::UnauthorizedError => e
      raise ::OpenAI::ConfigurationError
    end
  end

  private

  def client_method_name
    :chat
  end

  def configuration_error
    ::OpenAI::ConfigurationError
  end

  def set_client_config(config)
    super(config)

    @client_config = {
      parameters: {
        model: @assistant.language_model.api_name,
        messages: system_message(config[:instructions]) + config[:messages],
        stream: config[:streaming] && @response_handler || nil,
        max_tokens: 2000, # we should really set this dynamically, based on the model, to the max
        stream_options: config[:streaming] && { include_usage: true } || nil,
        response_format: { type: "text" },
        tools: @assistant.language_model.supports_tools? && Toolbox.tools || nil,
      }.compact.merge(config[:params] || {})
    }
  end

  def stream_handler(&chunk_handler)
    proc do |intermediate_response, bytesize|
      content_chunk = intermediate_response.dig("choices", 0, "delta", "content")
      tool_calls_chunk = intermediate_response.dig("choices", 0, "delta", "tool_calls")

      if (input_tokens, output_tokens = intermediate_response["usage"]&.values_at("prompt_tokens", "completion_tokens"))
        # https://platform.openai.com/docs/api-reference/chat/streaming
        @message.input_token_count = input_tokens
        @message.output_token_count = output_tokens
      end

      print content_chunk if Rails.env.development?
      if content_chunk
        @stream_response_text += content_chunk
        yield content_chunk
      end

      if tool_calls_chunk && tool_calls_chunk.is_a?(Array)
        tool_calls_chunk.each_with_index do |tool_call, i|
          @stream_response_tool_calls[i] ||= {}
          @stream_response_tool_calls[i] = deep_streaming_merge(@stream_response_tool_calls[i], tool_call)
        end
      end

    rescue ::GetNextAIMessageJob::ResponseCancelled => e
      raise e
    rescue ::Faraday::UnauthorizedError => e
      raise OpenAI::ConfigurationError
    rescue => e
      Rails.logger.info "\nUnhandled error in AIBackend::OpenAI response handler: #{e.message}"
      Rails.logger.info e.backtrace.join("\n")
    end
  end

  def system_message(content)
    [{
      role: "system",
      content:,
    }]
  end

  def preceding_conversation_messages
    @conversation.messages.for_conversation_version(@message.version).where("messages.index < ?", @message.index).collect do |message|
      if @assistant.supports_images? && message.documents.present?

        content_with_images = [{ type: "text", text: message.content_text }]
        content_with_images += message.documents.collect do |document|
          { type: "image_url", image_url: { url: document.image_url(:large) }}
        end

        {
          role: message.role,
          name: message.name_for_api,
          content: content_with_images,
        }.compact
      else
        {
          role: message.role,
          name: message.name_for_api,
          content: (JSON.parse(message.content_text).except("message_to_user").to_json rescue message.content_text),
          tool_calls: message.assistant? ? message.content_tool_calls : nil, # only for some assistant messages
          tool_call_id: message.tool_call_id,     # only for tool messages
        }.compact.except( message.content_tool_calls.blank? && :tool_calls )
      end
    end
  end

  def find_repeats_and_split(str)
    (1..str.length).each do |len|
      substring = str[0, len]
      repeated = substring * (str.length / len)
      return [substring] * (str.length / len) if repeated == str
    end
    [str]
  end
end
