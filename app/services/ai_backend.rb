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

    s += "\n\nWhen presenting mathematical formulas or equations, please use the following format:
        1. Use MathML syntax for all mathematical expressions.
        2. Present the formulas in a numbered table format using HTML.
        3. Each table row should contain three cells: the number, the name or description of the formula, and the MathML representation of the equation.
        4. Use the 'display=block' attribute in the math tag to ensure proper rendering.

        Example structure:

            1.
            Formula Name:

                [MathML representation of the equation]

        Please follow this format for all mathematical content unless specifically instructed otherwise."
    s.strip
  end
end
