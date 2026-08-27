module TestClient
  class Gemini
    def initialize(args)
    end

    def self.text
      nil
    end

    def self.function
      raise "Attempting to return a function response but .function method is not stubbed."
    end

    def self.arguments
      { "city" => "Austin", "state" => "TX", "country" => "US" }
    end

    def self.thought_signature
      "EqIBAdHtim9pbmc9dGhvdWdodF9zaWduYXR1cmU"
    end

    def self.payload
      @@payload
    end

    def self.blocked
      @@blocked ||= false
    end

    def self.blocked=(value)
      @@blocked = value
    end

    def generate_content(args)
      @@payload = args

      if self.class.blocked
        return { "promptFeedback" => { "blockReason" => "SAFETY" } }
      end

      text = self.class.text || default_text(args.dig(:system_instruction))

      {
        "candidates" =>
          [{"content"=>
            {"role"=>"model",
              "parts"=>[{"text"=> text}]},
            "finishReason"=>"STOP"}],
        "usageMetadata"=>{"promptTokenCount"=>1037, "candidatesTokenCount"=>31, "totalTokenCount"=>1068}
      }
    end

    private

    def default_text(system_message)
      "Hello this is a model with instruction #{system_message.to_s.inspect}! How can I assist you today?"
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
            [{"text"=> self.class.text || "Hello this is a model with instruction #{system_message.to_s.inspect}! How can I assist you today?"}]},
          "safetyRatings"=>
          [{"category"=>"HARM_CATEGORY_HARASSMENT", "probability"=>"NEGLIGIBLE"},
            {"category"=>"HARM_CATEGORY_HATE_SPEECH", "probability"=>"NEGLIGIBLE"},
            {"category"=>"HARM_CATEGORY_SEXUALLY_EXPLICIT", "probability"=>"NEGLIGIBLE"},
            {"category"=>"HARM_CATEGORY_DANGEROUS_CONTENT", "probability"=>"NEGLIGIBLE"}]}],
      "usageMetadata"=>{"promptTokenCount"=>1037, "candidatesTokenCount"=>31, "totalTokenCount"=>1068}
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
      "usageMetadata"=>{"promptTokenCount"=>1037, "candidatesTokenCount"=>31, "totalTokenCount"=>1068}
      }]
    end
  end
end
