class TestChat
  attr_reader :messages, :tools, :params, :instructions
  attr_accessor :model

  def initialize(assistant = nil)
    @assistant = assistant
    @messages = []
    @tools = []
    @params = {}
    @instructions = nil
    @model = assistant&.language_model&.api_name || "test-model"
  end

  def with_instructions(instructions)
    @instructions = instructions
    self
  end

  def with_params(**params)
    @params = params
    self
  end

  def with_tools(*tools)
    @tools.concat(tools.flatten)
    self
  end

  def with_tool(tool)
    @tools << tool
    self
  end

  def add_message(message_or_attributes)
    message = message_or_attributes.is_a?(RubyLLM::Message) ? message_or_attributes : RubyLLM::Message.new(message_or_attributes)
    @messages << message
    message
  end

  def complete(&block)
    if block_given?
      self.class.complete_streaming(self, &block)
    else
      self.class.complete_oneoff(self, @instructions, @messages, @params)
    end
  end

  def ask(message = nil, with: nil, &block)
    add_message(role: :user, content: message) if message
    complete(&block)
  end

  class << self
    attr_accessor :text, :function, :num_tool_calls, :arguments, :tool_id, :tokens, :chunks,
      :blank_response, :error_to_raise

    def reset
      @text = nil
      @function = nil
      @num_tool_calls = nil
      @arguments = {city: "Austin", state: "TX", country: "US"}.to_json
      @tool_id = "call_BlAN9iRiAD6aCzmBWCjzYxjj"
      @tokens = nil
      @chunks = nil
      @blank_response = false
      @error_to_raise = nil
    end

    def complete_oneoff(chat, instructions, messages, params = {})
      raise_error
      response_text = (text || default_text_for(chat)).to_s
      RubyLLM::Message.new(role: :assistant, content: response_text)
    end

    def complete_streaming(chat, &block)
      raise_error

      if function.present?
        tool_calls = build_tool_calls
        chat.add_message(role: :assistant, content: "", tool_calls: tool_calls)
      elsif chunks.present?
        chunks.each do |chunk_text, chunk_tokens|
          yield make_chunk(chunk_text, chunk_tokens) if block_given?
        end
        chat.add_message(role: :assistant, content: chunks.map(&:first).join)
      else
        response_text = (text || default_text_for(chat)).to_s
        unless response_text.empty?
          chunk = make_chunk(response_text, nil)
          yield chunk if block_given?
        end
        chat.add_message(role: :assistant, content: response_text)
      end
    end

    def default_text_for(chat)
      model = chat.respond_to?(:model) ? chat.model : nil
      instructions = chat.respond_to?(:instructions) ? chat.instructions : nil
      "Hello this is model #{model} with instruction #{instructions.inspect}! How can I assist you today?"
    end

    def make_chunk(content, tokens)
      tokens ||= token_payload
      Struct.new(:content, :tokens).new(content, tokens)
    end

    def token_payload
      return unless @tokens

      RubyLLM::Tokens.build(input: @tokens[:input], output: @tokens[:output])
    end

    def build_tool_calls
      tool_name = function
      tool_args = arguments || {city: "Austin", state: "TX", country: "US"}.to_json
      tool_args_hash = tool_args.is_a?(String) ? JSON.parse(tool_args) : tool_args
      call_id = tool_id || "call_#{SecureRandom.hex(12)}"

      num = num_tool_calls || 1
      calls = {}
      num.times do |i|
        id = (num > 1) ? "call_#{i}_#{SecureRandom.hex(10)}" : call_id
        calls[id] = RubyLLM::ToolCall.new(id: id, name: tool_name, arguments: tool_args_hash)
      end
      calls
    end

    def raise_error
      raise AIBackend::BlankResponseError if blank_response
      raise error_to_raise if error_to_raise
    end
  end

  reset
end
