require "test_helper"

class ChatCompletionAPITest < ActiveSupport::TestCase
  test "get_next_response responds with a reply" do
    stub_request(:post, ChatCompletionAPI.url).
    with(
      body: "{\"model\":\"gpt-3.5-turbo-1106\",\"max_tokens\":500,\"n\":1,\"response_format\":{\"type\":\"text\"},\"messages\":[{\"role\":\"system\",\"content\":\"I am a helpful assistant.\"},{\"role\":\"user\",\"content\":\"Can you hear me?\"}]}",
      headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization'=>'Bearer',
            'Content-Type'=>'application/json',
            'User-Agent'=>'Ruby'
      }).
    to_return(status: 200, body: "{\n  \"id\": \"chatcmpl-8NPlajQVlPaOgcic0mat6Bwp9JfoB\",\n  \"object\": \"chat.completion\",\n  \"created\": 1700591282,\n  \"model\": \"gpt-3.5-turbo-1106\",\n  \"choices\": [\n    {\n      \"index\": 0,\n      \"message\": {\n        \"role\": \"assistant\",\n        \"content\": \"No, I cannot hear you. I am an AI text-based assistant.\"\n      },\n      \"finish_reason\": \"stop\"\n    }\n  ],\n  \"usage\": {\n    \"prompt_tokens\": 21,\n    \"completion_tokens\": 60,\n    \"total_tokens\": 81\n  },\n  \"system_fingerprint\": \"fp_a24b4d720c\"\n}\n", headers: {})

    Current.user = users(:keith)
    response = ChatCompletionAPI.get_next_response("I am a helpful assistant.", ["Can you hear me?"])
    assert_equal "No, I cannot hear you. I am an AI text-based assistant.", response
  end
end
