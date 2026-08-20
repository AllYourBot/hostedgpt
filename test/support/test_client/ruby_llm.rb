module TestClient
  class RubyLLM
    class Chat
      attr_reader :messages

      def initialize(model:, provider: nil, assume_model_exists: nil, context: nil)
        @@model = model
        @context = context
        @messages = []
        @last_response = nil
      end

      def with_instructions(instructions)
        self.class.instance_variable_set(:@instructions, instructions)
        self
      end

      def with_params(**params)
        self.class.instance_variable_set(:@params, params)
        self
      end

      def with_tools(*tools)
        self.class.instance_variable_set(:@tools, tools)
        self
      end

      def add_message(msg)
        @messages << msg
        self
      end

      def complete(&block)
        raise self.class.error_to_raise if self.class.error_to_raise

        if block
          response = self.class.api_streaming_response
          block.call(response) if response.content.present?
        else
          @last_response = self.class.api_oneoff_response.dig("choices", 0, "message", "content")
        end
        self
      end

      def content
        @last_response
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
        content_text = if blank_response
          ""
        else
          text || default_text
        end
        t = tokens
        OpenStruct.new(
          content: content_text,
          input_tokens: t[:input_tokens],
          output_tokens: t[:output_tokens]
        )
      end

      def self.text
        raise "Attempting to return a text response but .text method is not stubbed. Stub this to nil if you want to return default text."
      end

      def self.default_text
        "Hello this is model #{@@model}! How can I assist you today?"
      end

      def self.blank_response
        false
      end

      def self.error_to_raise
        nil
      end

      def self.tokens
        { input_tokens: 8, output_tokens: 9 }
      end

      def self.arguments
        {city: "Austin", state: "TX", country: "US"}.to_json
      end

      def self.id
        "call_BlAN9iRiAD6aCzmBWCjzYxjj"
      end

      class << self
        attr_reader :instructions, :params, :tools
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
