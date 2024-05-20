class AIBackends::OpenAI
  attr :client

  # Rails system tests don't seem to allow mocking because the server and the
  # test are in separate processes.
  #
  # In regular tests, mock this method or the TestClients::OpenAI class to do
  # what you want instead.
  def self.client
    if Rails.env.test?
      TestClients::OpenAI
    else
      OpenAI::Client
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

    @stream_response_text = ""
    @tool_calls = []
  end

  def get_next_chat_message(&chunk_handler)
    tool_messages = [] # should these be persisted to the DB?
    response_handler = block_given? ? stream_handler(&chunk_handler) : nil

    loop do
      begin
        response = @client.chat(parameters: {
          model: @assistant.model,
          messages: system_message + preceding_messages + tool_messages,
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

      if @tool_calls.present?
        tool_messages << {
          role: "assistant",
          tool_calls: @tool_calls
        }
        tool_messages += generate_tool_messages(@tool_calls)
      elsif response_text.blank? && @stream_response_text.blank?
        raise ::Faraday::ParsingError
      else
        return response_text
      end

      @stream_response_text = ""
      @tool_calls = []
    end # loops until it returns or raises
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
          @tool_calls[i] ||= {}
          @tool_calls[i] = deep_streaming_merge(@tool_calls[i], tool_call)
        end
      end

    rescue ::GetNextAIMessageJob::ResponseCancelled => e
      raise e
    rescue ::Faraday::UnauthorizedError => e
      raise OpenAI::ConfigurationError
    rescue => e
      puts "\nUnhandled error in AIBackends::OpenAI response handler: #{e.message}"
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

        content = [{ type: "text", text: message.content_text }]
        content += message.documents.collect do |document|
          { type: "image_url", image_url: { url: document.file_data_url(:large) }}
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

  def generate_tool_messages(tool_calls)
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

  def deep_streaming_merge(hash1, hash2)
    merged_hash = hash1.dup
    hash2.each do |key, value|
      if merged_hash.has_key?(key) && merged_hash[key].is_a?(Hash) && value.is_a?(Hash)
        merged_hash[key] = deep_streaming_merge(merged_hash[key], value)
      elsif merged_hash.has_key?(key)
        merged_hash[key] += value
      else
        merged_hash[key] = value
      end
    end
    merged_hash
  end

  def deep_json_parse(obj)
    if obj.is_a?(Array)
      obj.map { |item| deep_json_parse(item) }
    else
      converted_hash = {}
      obj.each do |key, value|
        if value.is_a?(Hash)
          converted_hash[key] = deep_json_parse(value)
        else
          converted_hash[key] = begin
            JSON.parse(value)
          rescue => e
            value
          end
        end
      end
      converted_hash
    end
  end
end
