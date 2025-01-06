module TestClient
  class OpenAI
    attr_reader :uri_base

    def initialize(access_token:, uri_base:nil, api_version: "")
      @uri_base = uri_base
    end

    def self.text
      raise "Attempting to return a text response but .text method is not stubbed. Stub this to nil if you want to return default text."
    end

    def self.default_text
      "Hello this is model #{@@model} with instruction #{@@instruction.inspect}! How can I assist you today?"
    end

    def self.function
      raise "Attempting to return a function response but .function method is not stubbed."
    end

    def self.num_tool_calls
      1
    end

    def self.parameters
      @@parameters
    end

    def self.api_oneoff_response
      {
        "id"=>"chatcmpl-A0ZcGrOn1iO5bUgDVFMEj7pX6ZB9A",
        "object"=>"chat.completion",
        "created"=>1724700272,
        "model"=> @@model,
        "choices"=>[
          {
            "index"=>0,
            "message"=>{
              "role"=>"assistant",
              "content"=> text || default_text,
              "refusal"=>nil
            },
            "logprobs"=>nil,
            "finish_reason"=>"stop"
          }
        ],
        "usage"=>{"prompt_tokens"=>1243, "completion_tokens"=>11, "total_tokens"=>1254}
      }
    end

    def self.api_streaming_response
      {
        "id"=> "chatcmpl-abc123abc123abc123abc123abc12",
        "object"=>"chat.completion",
        "created"=>1707429030,
        "model"=> @@model,
        "choices"=> [
          {
            "index"=>0,
            "delta"=>{
              "role"=>"assistant",
              "content"=> text || default_text, #"Hello this is model #{model} with instruction #{system_message.to_s.inspect}! How can I assist you today?",
            },
            "logprobs"=>nil,
            "finish_reason"=>"stop"
          }
        ],
        "usage"=>{"prompt_tokens"=>8, "completion_tokens"=>9, "total_tokens"=>17},
        "system_fingerprint"=>nil
      }
    end

    def self.api_function_response
      {
        "choices" => [
          {
            "delta"=>{
              "tool_calls" => Array.new(num_tool_calls) {
                {
                  "index"=>0,
                  "id"=>id,
                  "type"=>"function",
                  "function"=>{
                    "name"=> function,
                    "arguments"=>arguments
                  }
                }
              }.map.with_index.map { |h, i| h["index"] = i; h }
            }
          }
        ]
      }
    end

    def self.id
      "call_BlAN9iRiAD6aCzmBWCjzYxjj"
    end

    def self.arguments
      {:city=>"Austin", :state=>"TX", :country=>"US"}.to_json
    end

    def chat(**args)
      @@model = args.dig(:parameters, :model) || "no model"
      @@instruction = args.dig(:parameters, :messages).first[:content]
      @@parameters = args.dig(:parameters)

      proc = args.dig(:parameters, :stream)
      tools = args.dig(:parameters, :tools)

      if proc && tools
        proc.call(self.class.api_function_response)
      elsif proc
        proc.call(self.class.api_streaming_response)
      else
        self.class.api_oneoff_response
      end
    end
  end
end
