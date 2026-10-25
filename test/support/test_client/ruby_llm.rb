module TestClient
  class RubyLLM
    class Chat
      attr_reader :messages, :headers

      def initialize(model:, provider: nil, assume_model_exists: nil, context: nil)
        @@model = model
        self.class.instance_variable_set(:@thinking_config, nil)
        self.class.instance_variable_set(:@provider_options, nil)
        @headers = {}
        @messages = []
        @last_response = nil
      end

      def with_headers(**headers)
        @headers = headers
        self
      end

      def with_instructions(instructions, cache_until_here: false)
        self.class.instance_variable_set(:@instructions, instructions)
        self.class.instance_variable_set(:@cache_until_here, cache_until_here)
        self
      end

      def with_provider_options(**options)
        self.class.instance_variable_set(:@provider_options, options)
        self
      end

      def with_thinking(**options)
        self.class.instance_variable_set(:@thinking_config, options)
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

      # Mirrors the real 2.0 generate: streams chunks to the block, never
      # executes tools, and returns the assistant message with tool_calls
      # populated (nil tool_calls for a text reply).
      def generate(&block)
        raise self.class.error_to_raise if self.class.error_to_raise

        # Like the real stream, thinking arrives before the text or the tool call.
        block&.call(OpenStruct.new(content: nil, tokens: nil, thinking: self.class.thinking)) if self.class.thinking

        if self.class.function
          return simulate_tool_calls
        end

        response = self.class.api_streaming_response
        block&.call(response) if response.content.present?
        message_double(content: response.content, tool_calls: nil)
      end

      def complete(&block)
        raise self.class.error_to_raise if self.class.error_to_raise

        if block
          generate(&block)
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

      private

      # Mirrors the real 2.0 tool flow: generate appends the assistant message
      # carrying the tool calls to messages and returns it — without executing
      # anything — so the backend reads tool_calls off the returned message.
      def simulate_tool_calls
        tool_calls = Array.new(self.class.num_tool_calls) do |i|
          ::RubyLLM::ToolCall.new(
            id: i.zero? ? self.class.id : "#{self.class.id}_#{i}",
            name: self.class.function,
            arguments: JSON.parse(self.class.arguments),
            thought_signature: self.class.thought_signature
          )
        end
        message = message_double(content: nil, tool_calls: tool_calls.to_h { |tc| [tc.id, tc] })
        @messages << message
        message
      end

      def message_double(content:, tool_calls:)
        OpenStruct.new(role: :assistant, content:, tool_calls:)
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
          tokens: OpenStruct.new(input: t[:input], output: t[:output])
        )
      end

      def self.text
        raise "Attempting to return a text response but .text method is not stubbed. Stub this to nil if you want to return default text."
      end

      # Returns the name of the tool the model "requested"; nil means the model
      # responds with text instead. Mirrors TestClient::OpenAI#function.
      def self.function
        nil
      end

      def self.num_tool_calls
        1
      end

      # Gemini attaches a thought signature to each tool call; other providers
      # issue none. Stub this to simulate Gemini.
      def self.thought_signature
        nil
      end

      # A ::RubyLLM::Thinking streamed ahead of the response; nil means the model
      # didn't think. Stub this to simulate extended thinking.
      def self.thinking
        nil
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
        { input: 8, output: 9 }
      end

      def self.arguments
        {city: "Austin", state: "TX", country: "US"}.to_json
      end

      def self.id
        "call_BlAN9iRiAD6aCzmBWCjzYxjj"
      end

      class << self
        attr_reader :instructions, :cache_until_here, :provider_options, :tools, :thinking_config
      end
    end

    class ContextDouble
      attr_accessor :openai_api_key, :anthropic_api_key, :gemini_api_key,
        :openai_api_base, :anthropic_api_base, :gemini_api_base,
        :openai_use_system_role

      def paint(prompt, **kwargs)
        raise self.class.paint_error_to_raise if self.class.paint_error_to_raise

        self.class.last_paint_call = { prompt: prompt, kwargs: kwargs, openai_api_key: openai_api_key }
        OpenStruct.new(data: self.class.image_data, url: self.class.image_url, mime_type: "image/png")
      end

      def speak(text, **kwargs)
        raise self.class.speak_error_to_raise if self.class.speak_error_to_raise

        self.class.last_speak_call = { text: text, kwargs: kwargs, openai_api_key: openai_api_key, gemini_api_key: gemini_api_key }
        SpeechBytes.new(self.class.speech_data || "RUBYLLM_WAV_BYTES")
      end

      class << self
        attr_accessor :image_url, :paint_error_to_raise, :last_paint_call,
          :speech_data, :speak_error_to_raise, :last_speak_call

        def image_data
          @image_data || "RUBYLLM_BASE64_IMAGE_DATA"
        end

        def reset_recordings!
          @last_paint_call = nil
          @image_data = nil
          @image_url = nil
          @paint_error_to_raise = nil
          @last_speak_call = nil
          @speech_data = nil
          @speak_error_to_raise = nil
        end
      end
    end

    # Mirrors RubyLLM::Speech#to_blob for the fake: carries the raw audio bytes.
    SpeechBytes = Struct.new(:data) do
      def to_blob
        data
      end
    end

    def self.context(&block)
      ctx = ContextDouble.new
      block.call(ctx) if block
      ctx
    end
  end
end
