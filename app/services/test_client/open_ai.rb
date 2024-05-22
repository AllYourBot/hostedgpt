class TestClient::OpenAI
  def initialize(access_token:)
  end

  def self.api_response
    raise "When using the OpenAI test client you need to stub the .api_response method typically with either text_response or function_call_response"
  end

  def self.text
    raise "When using the OpenAI test client for api_text_response you need to stub the .text method"
  end

  def self.api_text_response
    {
      "id"=> "chatcmpl-abc123abc123abc123abc123abc12",
      "object"=>"chat.completion",
      "created"=>1707429030,
      "model"=>"gpt-3.5-turbo-0613",
      "choices"=> [
        {
          "index"=>0,
          "delta"=>{
            "role"=>"assistant",
            "content"=> text
          },
          "logprobs"=>nil,
          "finish_reason"=>"stop"
        }
      ],
      "usage"=>{"prompt_tokens"=>8, "completion_tokens"=>9, "total_tokens"=>17},
      "system_fingerprint"=>nil
    }
  end

  def self.function
    raise "When using the OpenAI test client for api_function_response you need to stub the .function method"
  end

  def self.api_function_response
    {
      "choices" => [
        {
          "delta"=>{
            "tool_calls" => [
              {
                "index"=>0,
                "id"=>"call_BlAN9iRiAD6aCzmBWCjzYxjj",
                "type"=>"function",
                "function"=>{
                  "name"=> function,
                  "arguments"=>{:city=>"Austin", :state=>"TX", :country=>"US"}
                }
              }
            ]
          }
        }
      ]
    }
  end

  def chat(**args)
    proc = args.dig(:parameters, :stream)
    raise "No stream proc provided. When calling get_next_chat_message in tests be sure to include a block" if proc.nil?
    proc.call(self.class.api_response)
  end
end