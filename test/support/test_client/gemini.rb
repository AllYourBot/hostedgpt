module TestClient
  class Gemini
    USAGE_METADATA = { "promptTokenCount" => 1037, "candidatesTokenCount" => 31, "totalTokenCount" => 1068 }.freeze

    def initialize(args)
    end

    class << self
      attr_accessor :blocked

      def payload
        @@payload
      end

      def reset_recordings!
        @@payload = nil
        self.blocked = false
      end

      def text
        nil
      end

      def function
        raise "Attempting to return a function response but .function method is not stubbed."
      end

      def arguments
        { "city" => "Austin", "state" => "TX", "country" => "US" }
      end

      def thought_signature
        "EqIBAdHtim9pbmc9dGhvdWdodF9zaWduYXR1cmU"
      end

      def default_text(system_message)
        "Hello this is a model with instruction #{system_message.to_s.inspect}! How can I assist you today?"
      end
    end

    def generate_content(args)
      @@payload = args

      if self.class.blocked
        return { "promptFeedback" => { "blockReason" => "SAFETY" } }
      end

      text = self.class.text || self.class.default_text(args.dig(:system_instruction))

      {
        "candidates" =>
          [{"content"=>
            {"role"=>"model",
              "parts"=>[{"text"=> text}]},
            "finishReason"=>"STOP"}],
        "usageMetadata"=> USAGE_METADATA
      }
    end

    # This response is a valid example response from the API.
    #
    # Stub this method to respond with something more specific if needed.
    def stream_generate_content(args)
      contents = args.dig(:contents)
      system_message = args.dig(:system_instruction)

      return api_function_response if args.dig(:tools).present?

      [{"candidates"=>
        [{"content"=>
          {"role"=>"model",
            "parts"=>
            [{"text"=> self.class.text || self.class.default_text(system_message)}]},
          "safetyRatings"=>
          [{"category"=>"HARM_CATEGORY_HARASSMENT", "probability"=>"NEGLIGIBLE"},
            {"category"=>"HARM_CATEGORY_HATE_SPEECH", "probability"=>"NEGLIGIBLE"},
            {"category"=>"HARM_CATEGORY_SEXUALLY_EXPLICIT", "probability"=>"NEGLIGIBLE"},
            {"category"=>"HARM_CATEGORY_DANGEROUS_CONTENT", "probability"=>"NEGLIGIBLE"}]}],
      "usageMetadata"=>USAGE_METADATA
      }]
    end

    private

    def api_function_response
      [{"candidates"=>
        [{"content"=>
          {"role"=>"model",
            "parts"=>
            [{"functionCall"=>{
              "name"=> self.class.function,
              "args"=> self.class.arguments.deep_stringify_keys
            },
            "thoughtSignature"=> self.class.thought_signature}]},
          "finishReason"=>"STOP"}],
      "usageMetadata"=>USAGE_METADATA
      }]
    end
  end
end
