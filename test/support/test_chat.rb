class TestChat
  attr_reader :messages, :tools, :params, :instructions
  attr_accessor :model

  def initialize(api_service = nil, assistant = nil)
    @api_service = api_service
    @assistant = assistant
    @messages = []
    @tools = []
    @params = {}
    @instructions = nil
    @model = assistant&.language_model&.api_name || "test-model"
  end

  def with_instructions(instructions, append: false, replace: nil)
    @instructions = instructions
    self
  end

  def with_params(**params)
    @params = @params.merge(params)
    self
  end

  def with_tools(*tools, **)
    @tools.concat(tools.flatten)
    self
  end

  def with_tool(tool, **)
    @tools << tool
    self
  end

  def add_message(message_or_attributes)
    message = message_or_attributes.is_a?(RubyLLM::Message) ? message_or_attributes : RubyLLM::Message.new(message_or_attributes)
    @messages << message
    message
  end

  def complete(&block)
    block_given? ? complete_streaming(&block) : complete_oneoff
  end

  def ask(message = nil, with: nil, &block)
    add_message(role: :user, content: message) if message
    complete(&block)
  end

  class << self
    attr_accessor :text, :function, :num_tool_calls, :arguments, :tool_id

    def reset
      @text = nil
      @function = nil
      @num_tool_calls = nil
      @arguments = { :city=>"Austin", :state=>"TX", :country=>"US" }.to_json
      @tool_id = "call_BlAN9iRiAD6aCzmBWCjzYxjj"
    end

    def complete_oneoff(chat, instructions, messages, params = {})
      response_text = (text || default_text_for(chat)).to_s
      RubyLLM::Message.new(role: :assistant, content: response_text)
    end

    def complete_streaming(chat, assistant, message)
      response_text = (text || default_text_for(chat)).to_s

      if function.present?
        tool_calls = build_tool_calls
        chat.add_message(role: :assistant, content: "", tool_calls: tool_calls)
      else
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
      Struct.new(:content, :tokens).new(content, tokens)
    end

    def build_tool_calls
      tool_name = function
      tool_args = arguments || { :city=>"Austin", :state=>"TX", :country=>"US" }.to_json
      tool_args_hash = tool_args.is_a?(String) ? JSON.parse(tool_args) : tool_args
      call_id = tool_id || "call_#{SecureRandom.hex(12)}"

      num = num_tool_calls || 1
      calls = {}
      num.times do |i|
        id = num > 1 ? "call_#{i}_#{SecureRandom.hex(10)}" : call_id
        calls[id] = RubyLLM::ToolCall.new(id: id, name: tool_name, arguments: tool_args_hash)
      end
      calls
    end
  end

  reset
end
