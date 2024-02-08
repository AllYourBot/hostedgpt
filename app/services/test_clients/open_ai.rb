class TestClients::OpenAi
  def initialize(access_token:)
  end

  # This response is a valid example response from the API.
  #
  # Stub this method to respond with something more specific if needed.
  def chat(**args)
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
            "content"=>"Hello! How can I assist you today?"
          },
          "logprobs"=>nil,
          "finish_reason"=>"stop"
        }
      ],
      "usage"=>{"prompt_tokens"=>8, "completion_tokens"=>9, "total_tokens"=>17},
      "system_fingerprint"=>nil
    }
  end
end
