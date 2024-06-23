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

  def initialize(user, assistant, conversation, message)
    super(user, assistant, conversation, message)
    begin
      raise ::OpenAI::ConfigurationError if assistant.api_service.requires_token? && assistant.api_service.token.blank?
      Rails.logger.info "Connecting to OpenAI API server at #{assistant.api_service.url} with access token of length #{assistant.api_service.token.to_s.length}"
      @client = self.class.client.new(uri_base: assistant.api_service.url, access_token: assistant.api_service.token)
    rescue ::Faraday::UnauthorizedError => e
      raise ::OpenAI::ConfigurationError
    end
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
      format_parallel_tool_calls(@stream_response_tool_calls)
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
      puts "\nUnhandled error in AIBackend::OpenAI response handler: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end

  def system_message
    [{
      role: "system",
      content: full_instructions.to_s + "\nThe current time & date for the user is " + DateTime.current.strftime("%-l:%M%P on %A, %B %-d, %Y")
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

  def format_parallel_tool_calls(content_tool_calls)
    if content_tool_calls.length > 1 || (calls = content_tool_calls.dig(0, "id"))&.scan("call_").length == 1
      return content_tool_calls
    end

    names = find_repeats_and_split(content_tool_calls.dig(0, "function", "name"))
    args = content_tool_calls.dig(0, "function", "arguments").split(/(?<=})(?={)/)

    calls.split(/(?=call_)/).map.with_index do |id, i|
      {
        index: i,
        type: "function",
        id: id[0...40],
        function: {
          name: names.fetch(i),
          arguments: args.fetch(i),
        }
      }
    end
  rescue
    {}
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
