class TestClients::OpenAI
  def initialize(access_token:)
  end

  def self.text
    nil
  end

  # This response is a valid example response from the API.
  #
  # Stub this method to respond with something more specific if needed.
  def chat(**args)
    if proc = args.dig(:parameters, :stream)
      proc.call({
        "id"=> "chatcmpl-abc123abc123abc123abc123abc12",
        "object"=>"chat.completion",
        "created"=>1707429030,
        "model"=>"gpt-3.5-turbo-0613",
        "choices"=> [
          {
            "index"=>0,
            "delta"=>{
              "role"=>"assistant",
              "content"=>self.class.text || "Hello! How can I assist you today?"
            },
            "logprobs"=>nil,
            "finish_reason"=>"stop"
          }
        ],
        "usage"=>{"prompt_tokens"=>8, "completion_tokens"=>9, "total_tokens"=>17},
        "system_fingerprint"=>nil
      })
    else
      {
        "id"=> "chatcmpl-abc123abc123abc123abc123abc12",
        "object"=>"chat.completion",
        "created"=>1707429030,
        "model"=>"gpt-3.5-turbo-0613",
        "choices"=> [
          {
            "index"=>0,
            "message"=>{
              "role"=>"assistant",
              "content"=>self.class.text || "Hello! How can I assist you today?"
            },
            "logprobs"=>nil,
            "finish_reason"=>"stop"
          }
        ],
        "usage"=>{"prompt_tokens"=>8, "completion_tokens"=>9, "total_tokens"=>17},
        "system_fingerprint"=>nil

      }.dig("choices", 0, "message", "content")
    end
  end
end
