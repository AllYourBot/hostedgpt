module TestClient
  class RubyLLM
    class Chat
      attr_reader :messages

      def initialize(model:, provider: nil, assume_model_exists: nil, context: nil)
        @@model = model
        @context = context
        @messages = []
      end

      def with_instructions(instructions)
        @@instructions = instructions
        self
      end

      def with_params(**params)
        @@params = params
        self
      end

      def with_tools(*tools)
        @@tools = tools
        self
      end

      def add_message(msg)
        @messages << msg
        self
      end

      def complete(&block)
        if block
          block.call(self.class.api_streaming_response)
        else
          self.class.api_oneoff_response.dig("choices", 0, "message", "content")
        end
      end

      def ask(message = nil, with: nil, &block)
        add_message({role: "user", content: message}) if message
        complete(&block)
      end

      def self.api_oneoff_response
        {
          "choices" => [
            {
              "message" => {
                "content" => text || default_text
              }
            }
          ]
        }
      end

      def self.api_streaming_response
        OpenStruct.new(
          content: text || default_text,
          input_tokens: 8,
          output_tokens: 9
        )
      end

      def self.text
        raise "Attempting to return a text response but .text method is not stubbed. Stub this to nil if you want to return default text."
      end

      def self.default_text
        "Hello this is model #{@@model}! How can I assist you today?"
      end

      class << self
        attr_reader :instructions, :params
      end
    end

    class ContextDouble
      attr_accessor :openai_api_key, :anthropic_api_key, :gemini_api_key,
        :openai_api_base, :anthropic_api_base, :gemini_api_base
    end

    def self.context(&block)
      ctx = ContextDouble.new
      block.call(ctx) if block
      ctx
    end
  end
end
