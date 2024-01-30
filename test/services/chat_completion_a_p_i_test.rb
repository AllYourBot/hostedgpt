require "test_helper"

class ChatCompletionAPITest < ActiveSupport::TestCase
  test "get_next_response responds with a reply" do
    ChatCompletionAPI.stubs(:formatted_api_response).returns("No, I cannot hear you. I am an AI text-based assistant.")
    Current.user = users(:keith)

    response = ChatCompletionAPI.get_next_response("I am a helpful assistant.", ["Can you hear me?"])
    assert_equal "No, I cannot hear you. I am an AI text-based assistant.", response
  end

  test "get_next_response with an invalid response_format raises" do
    Current.user = users(:keith)
    error = assert_raises do
      response = ChatCompletionAPI.get_next_response("I am a helpful assistant.", ["Can you hear me?"], response_format: "json_object" )
    end
    assert_match /response_format is invalid/, error.message
  end

  test "get_next_response with response_format of json returns a hash" do
    ChatCompletionAPI.stubs(:formatted_api_response).returns("{\"response\":\"yes\"}")
    Current.user = users(:keith)

    response = nil
    assert_nothing_raised do
      response = ChatCompletionAPI.get_next_response("Reply with the JSON { response: 'yes' }", ["Give me the reply."], response_format: { type: "json_object" } )
    end
    assert_equal({"response"=>"yes"}, response)
  end

end
