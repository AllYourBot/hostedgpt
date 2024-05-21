class AIBackend::OpenAI < AIBackend
  # Rails system tests don't seem to allow mocking because the server and the
  # test are in separate processes.
  #
  # In regular tests, mock this method or the TestClients::OpenAI class to do
  # what you want instead.
  def self.client
    if Rails.env.test?
      ::TestClients::OpenAI
    else
      ::OpenAI::Client
    end
  end

  def initialize(user, assistant, conversation, message)
    raise OpenAI::ConfigurationError if user.openai_key.blank?
    begin
      @client = self.class.client.new(access_token: user.openai_key)
    rescue ::Faraday::UnauthorizedError => e
      raise OpenAI::ConfigurationError
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
        model: @assistant.model,
        messages: system_message + preceding_messages,
        tools: OpenWeather.tools,
        stream: response_handler,
        max_tokens: 2000, # we should really set this dynamically, based on the model, to the max
      })
    rescue ::Faraday::UnauthorizedError => e
      raise OpenAI::ConfigurationError
    end

    response_text = if response.is_a?(Hash) && response.dig("choices")
      response.dig("choices", 0, "message", "content")
    else
      response
    end

    if response.is_a?(Hash) && response.present?
      return { "choices": [ response.dig("choices", 0, "delta") ] }
    elsif response_text.blank? && response.blank?
      raise ::Faraday::ParsingError
    else
      return response_text
    end
  end

  def get_tool_messages(tool_calls)
    # We could parallelize function calling using ruby threads
    tool_calls.map do |tool_call|
      tool_call = deep_json_parse(tool_call)
      id = tool_call.dig("id")
      function_name = tool_call.dig("function", "name")
      function_arguments = tool_call.dig("function", "arguments")
      raise "Unexpected tool call: #{id}, #{function_name}, and #{function_arguments}" if function_name.blank? || function_arguments.blank?
      function_response = Toolbox.call(function_name, function_arguments)

      {
        role: "tool",
        content: function_response.to_json,
        tool_call_id: id,
      }
    end
  rescue => e
    puts "## Error calling tools: #{e.message}"
    puts e.backtrace.join("\n")
    raise ::Faraday::ParsingError
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
      if @assistant.images && message.documents.present?

        content_with_images = [{ type: "text", text: message.content_text }]
        content_with_images += message.documents.collect do |document|
          document.file_data_url(:large) # this is a blocoking call to ensure the image generates
          { type: "image_url", image_url: { url: document.document_image_path(:large, fallback: "") }}
        end

        {
          role: message.role,
          name: message.name,
          content: content_with_images
        }.compact
      else
        {
          role: message.role,
          name: message.name,
          content: message.content_text || "",
          tool_call_id: message.tool_call_id
        }.compact
      end
    end
  end
end
