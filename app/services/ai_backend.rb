require "timeout"

class AIBackend
  include Utilities, Tools

  class ConfigurationError < StandardError; end

  attr :client

  def self.oneoff_timeout_seconds
    30
  end

  def self.key_error_message
    "(There is a configuration error with this API Service. Maybe you have an invalid API key? " +
      "Click your Profile in the bottom left and then Settings and then **API Services**.)"
  end

  def self.billing_url
  end

  # New backends: override this to deny tool calls — a backend whose tool
  # support is not yet proven should pin it to false.
  def self.supports_tools?
    true
  end

  def initialize(user, assistant, conversation = nil, message = nil)
    @user = user
    @assistant = assistant
    @conversation = conversation
    @message = message # required for streaming responses
    @client_config = {}
    @response_handler = nil
  end

  def get_oneoff_message(instructions, messages, params = {}, json: false)
    set_client_config(
      instructions:,
      messages: preceding_messages(messages),
      params:,
      json:,
    )
    response = Timeout.timeout(self.class.oneoff_timeout_seconds) do
      @client.send(client_method_name, ** @client_config)
    end

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
    rescue ::Faraday::UnauthorizedError
      raise AIBackend::ConfigurationError
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
    language_models = api_service.language_models.order(created_at: :desc)

    return "Error: API key (token) is blank" if api_service.requires_token? && token.blank?
    return "Error: API name is blank. Define a Language Model for this API service." if language_models.none?

    # A provider can retire a model out from under us, so don't bet the whole test on
    # whichever language model happens to be first; walk newest-first until one answers.
    result = nil
    language_models.each do |language_model|
      result = test_execute(url, token, language_model.api_name)
      break unless result.start_with?("Error:")
    end
    result
  end

  # New backends: override this or accept OpenAI delegation — until a provider
  # ships native image generation, OpenAI covers the capability for everyone.
  def self.generate_image(prompt:, user:)
    AIBackend::OpenAI.generate_image(prompt:, user:)
  end

  private

  def client_method_name
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
