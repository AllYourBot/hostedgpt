class AIBackend::OpenAI < AIBackend
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

  def self.get_tool_messages_by_calling(tool_calls_response)
    tool_calls = deep_json_parse(tool_calls_response)

    # We could parallelize function calling using ruby threads
    tool_calls.map do |tool_call|
      id = tool_call.dig(:id)
      function_name = tool_call.dig(:function, :name)
      function_arguments = tool_call.dig(:function, :arguments)

      raise "Unexpected tool call: #{id}, #{function_name}, and #{function_arguments}" if function_name.blank? || function_arguments.nil?

      function_response = begin
        Toolbox.call(function_name, function_arguments)
      rescue => e
        puts "## Handled error calling tools: #{e.message}" unless Rails.env.test?
        puts e.backtrace.join("\n") unless Rails.env.test?

        <<~STR.gsub("\n", " ")
          An unexpected error occurred. You were requesting this information to help you answer a users question. Because this information
          is not available at this time, DO NOT MAKE ANY GUESSES as you attempt to answer the users questions. Instead, you can let the
          user know you attempted to retrieve some information in order to answer their question but you had some difficulties accessing
          the website at this time.
        STR
      end

      {
        role: "tool",
        content: function_response.to_json,
        tool_call_id: id,
      }
    end
  rescue => e
    puts "## UNHANDLED error calling tools: #{e.message}"
    puts e.backtrace.join("\n")
    raise ::Faraday::ParsingError
  end

  def initialize(user, assistant, conversation, message)
    begin
      if assistant.api_service.blank?
        raise ::OpenAI::ConfigurationError if user.openai_key.blank?
        @client = self.class.client.new(access_token: user.openai_key)
      else
        Rails.logger.info "Connecting to API server at #{assistant.api_service.url} with access token of length #{assistant.api_service.access_token.to_s.length}"
        @client = self.class.client.new(uri_base: assistant.api_service.url, access_token: assistant.api_service.access_token)
      end
    rescue ::Faraday::UnauthorizedError => e
      raise ::OpenAI::ConfigurationError
    end
    @assistant = assistant
    @conversation = conversation
    @message = message
  end

  def get_next_chat_message(&chunk_handler)
    @stream_response_text = ""
    @stream_response_tool_calls = []
    response_handler = block_given? ? stream_handler(&chunk_handler) : nil

    begin
      response = @client.chat(parameters: {
        model: @assistant.language_model.provider_name,
        messages: system_message + preceding_messages,
        tools: Toolbox.tools,
        stream: response_handler,
        max_tokens: 2000, # we should really set this dynamically, based on the model, to the max
      })
    rescue ::Faraday::UnauthorizedError => e
      raise ::OpenAI::ConfigurationError
    end

    if @stream_response_tool_calls.present?
      return @stream_response_tool_calls
    elsif @stream_response_text.blank?
      raise ::Faraday::ParsingError
    end
  end

  private

  def stream_handler(&chunk_received_handler)
    proc do |intermediate_response, bytesize|
      content_chunk = intermediate_response.dig("choices", 0, "delta", "content")
      tool_calls_chunk = intermediate_response.dig("choices", 0, "delta", "tool_calls")

      print content_chunk if Rails.env.development?
      if content_chunk
        @stream_response_text += content_chunk
        yield content_chunk
      elsif tool_calls_chunk && tool_calls_chunk.is_a?(Array)
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
      puts "\nUnhandled error in AIBackend::OpenAI response handler: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end

  def system_message
    return [] if @assistant.instructions.blank?

    [{
      role: 'system',
      content: @assistant.instructions
    }]
  end

  def preceding_messages
    @conversation.messages.for_conversation_version(@message.version).where("messages.index < ?", @message.index).collect do |message|
      if @assistant.supports_images? && message.documents.present?

        content_with_images = [{ type: "text", text: message.content_text }]
        content_with_images += message.documents.collect do |document|
          { type: "image_url", image_url: { url: document.file_data_url(:large) }}
        end

        {
          role: message.role,
          name: message.name,
          content: content_with_images,
        }.compact
      else
        {
          role: message.role,
          name: message.name,
          content: message.content_text,
          tool_calls: message.content_tool_calls, # only for some assistant messages
          tool_call_id: message.tool_call_id,     # only for tool messages
        }.compact.except( message.content_tool_calls.blank? && :tool_calls )
      end
    end
  end
end
