module TestClient
  class Gemini
    def initialize(args)
    end

    def self.text
      nil
    end

    # This response is a valid example response from the API.
    #
    # Stub this method to respond with something more specific if needed.
    def stream_generate_content(args)
      contents = args.dig(:contents)
      system_message = args.dig(:system_instruction)
      return [{"candidates"=>
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
  end
end
