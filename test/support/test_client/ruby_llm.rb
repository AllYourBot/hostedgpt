require "ostruct"

module TestClient
  class RubyLLM
    def self.text
      raise "Attempting to return a text response but .text method is not stubbed. Stub this to nil if you want to return default text."
    end

    def self.default_text
      "Hello! How can I assist you today?"
    end

    def self.function
      raise "Attempting to return a function response but .function method is not stubbed."
    end

    def self.arguments
      { city: "Austin", state: "TX", country: "US" }.to_json
    end

    def self.tool_call_id
      "call_BlAN9iRiAD6aCzmBWCjzYxjj"
    end

    @function_stubbed = false
    class << self
      attr_accessor :function_stubbed
    end

    def self.context
      yield OpenStruct.new
      OpenStruct.new
    end

    class Chat
      def initialize(model:, provider:, assume_model_exists:, context:)
        @model = model
        @messages = []
        @instructions = nil
        @params = {}
        @tools = []
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
        @tools = tools
        self
      end

      def add_message(msg)
        @messages << msg
        self
      end

      def complete(&block)
        if block_given?
          if TestClient::RubyLLM.function_stubbed
            yield_tool_calls(&block)
          else
            yield_text(&block)
          end
        else
          if TestClient::RubyLLM.function_stubbed
            tool_call_response
          else
            text_response
          end
        end
      end

      def ask(message = nil, with: nil, &block)
        add_message(role: :user, content: message) if message
        complete(&block)
      end

      private

      def yield_text
        text = TestClient::RubyLLM.text || TestClient::RubyLLM.default_text
        chunk = OpenStruct.new(
          content: text,
          tool_calls: nil,
          input_tokens: 10,
          output_tokens: 20,
        )
        yield chunk
        text_response
      end

      def yield_tool_calls
        chunk = OpenStruct.new(
          content: nil,
          tool_calls: nil,
          input_tokens: 10,
          output_tokens: 5,
        )
        yield chunk
        tool_call_response
      end

      def text_response
        OpenStruct.new(
          content: TestClient::RubyLLM.text || TestClient::RubyLLM.default_text,
          tool_calls: nil,
        )
      end

      def tool_call_response
        tc = OpenStruct.new(
          id: TestClient::RubyLLM.tool_call_id,
          name: TestClient::RubyLLM.function,
          arguments: JSON.parse(TestClient::RubyLLM.arguments),
        )
        OpenStruct.new(
          content: nil,
          tool_calls: { tc.id => tc },
        )
      end
    end
  end
end
