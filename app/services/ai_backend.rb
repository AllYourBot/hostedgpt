class AIBackend
  include Utilities, Tools

  attr :client

  def initialize(user, assistant, conversation = nil, message = nil)
    @user = user
    @assistant = assistant
    @conversation = conversation
    @message = message # required for streaming responses
    @client_config = {}
    @response_handler = nil
  end

  def get_oneoff_message(instructions, messages, params = {})
    set_client_config(
      instructions:,
      messages: preceding_messages(messages),
      params:,
    )
    response = @client.send(client_method_name, ** @client_config)

    response.dig("content", 0, "text") ||
      response.dig("choices", 0, "message", "content")
  end

  def stream_next_conversation_message(&chunk_handler)
    @stream_response_text = ""
    @stream_response_tool_calls = []
    @response_handler = block_given? ? stream_handler(&chunk_handler) : nil

    set_client_config(
      instructions: full_instructions,
      messages: preceding_conversation_messages,
      streaming: true,
    )

    begin
      response = @client.send(client_method_name, ** @client_config)
    rescue ::Faraday::UnauthorizedError => e
      raise configuration_error
    end

    if @stream_response_tool_calls.present?
      return format_parallel_tool_calls(@stream_response_tool_calls)
    elsif @stream_response_text.blank?
      raise ::Faraday::ParsingError
    end
  end

  def self.test_language_model(language_model, api_name = nil)
    api_name ||= language_model.api_name
    url = language_model.api_service.url
    token = language_model.api_service.effective_token
    return "Error: API key (token) is blank" if language_model.api_service.requires_token? && token.blank?

    test_execute(url, token, api_name)
  end

  def self.test_api_service(api_service, url = nil, token = nil)
    url ||= api_service.url
    token ||= api_service.effective_token
    language_model = LanguageModel.where(best: true, api_service: api_service).first
    api_name = language_model.api_name unless language_model.nil?

    return "Error: API key (token) is blank" if api_service.requires_token? && token.blank?
    return "Error: API name is blank. Define a best Language Model for this API service." if api_name.blank?

    test_execute(url, token, api_name)
  end

  private

  def client_method_name
    raise NotImplementedError
  end

  def configuration_error
    raise NotImplementedError
  end

  def set_client_config(config)
    if config[:streaming] && @response_handler.nil?
      raise "You configured streaming: true but did not define @response_handler"
    end
  end

  def get_response
    raise NotImplementedError
  end

  def stream_response
    raise NotImplementedError
  end

  def preceding_messages(messages = [])
    messages.map.with_index do |msg, i|
      role = (i % 2).zero? ? "user" : "assistant"

      {
        role:,
        content: msg
      }
    end
  end

  def preceding_conversation_messages
    raise NotImplementedError
  end

  def full_instructions
    s = @assistant.instructions.to_s

    if @user.memories.present?
      s += "\n\nNote these additional items that you've been told and remembered:\n\n"
      s += @user.memories.pluck(:detail).join("\n")
    end

    s += "\n\nFor the user, the current time is #{DateTime.current.strftime("%-l:%M%P")}; the current date is #{DateTime.current.strftime("%A, %B %-d, %Y")}"
    s.strip
  end
end
