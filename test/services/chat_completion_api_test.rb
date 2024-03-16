require "test_helper"

class ChatCompletionAPITest < ActiveSupport::TestCase
  test "get_next_response responds with a reply" do
    Current.user = users(:keith)

    response = ChatCompletionAPI.stub :formatted_api_response, "No, I cannot hear you. I am an AI text-based assistant." do
      ChatCompletionAPI.get_next_response("I am a helpful assistant.", ["Can you hear me?"])
    end
    assert_equal "No, I cannot hear you. I am an AI text-based assistant.", response
  end

  test "get_next_response with an invalid response_format raises" do
    Current.user = users(:keith)
    error = assert_raises do
      ChatCompletionAPI.get_next_response("I am a helpful assistant.", ["Can you hear me?"], response_format: "json_object" )
    end
    assert_match /response_format is invalid/, error.message
  end

  test "get_next_response with response_format of json returns a hash" do
    Current.user = users(:keith)

    ChatCompletionAPI.stub :formatted_api_response, "{\"response\":\"yes\"}" do
      response = assert_nothing_raised do
        ChatCompletionAPI.get_next_response("Reply with the JSON { response: 'yes' }", ["Give me the reply."], response_format: { type: "json_object" } )
      end
      assert_equal({"response"=>"yes"}, response)
    end
  end
end
