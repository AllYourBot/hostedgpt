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
  end

  def get_next_chat_message(&chunk_received_handler)
    puts "starting get_next"

    stream_response_text = ""
    tool_calling_response = []

    response_handler = proc do |intermediate_response, bytesize|
      content_chunk = intermediate_response.dig("choices", 0, "delta", "content")
      tool_calls = intermediate_response.dig("choices", 0, "delta", "tool_calls")

      print content_chunk if Rails.env.development?
      if content_chunk
        stream_response_text += content_chunk
        yield content_chunk
      elsif tool_calls && tool_calls.is_a?(Array)
        tool_calls.each_with_index do |tool_call, i|
          tool_calling_response[i] ||= {}
          tool_calling_response[i] = deep_streaming_merge(tool_calling_response[i], tool_call)
        end
      end

    rescue ::GetNextAIMessageJob::ResponseCancelled => e
      raise e
    rescue ::Faraday::UnauthorizedError => e
      raise OpenAI::ConfigurationError
    rescue => e
      puts "\nUnhandled error in AIBackends::OpenAI response handler: #{e.message}"
      puts e.backtrace
    end

    response_handler = nil unless block_given?

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

    if tool_calling_response.present?
      tool_calling_response = deep_json_parse(tool_calling_response)
      tool_calling_response.each do |tool_call|
        # TODO: call tool and add onto the messages.
      end
    elsif response_text.blank? && stream_response_text.blank?
      raise ::Faraday::ParsingError
    else
      response_text
    end
  end

  private

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
