require "test_helper"

class AIBackend::OpenAI::ToolsTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:attachments)
    @assistant = assistants(:keith_gpt4)
    @assistant.language_model.update!(supports_tools: false) # this will change the TestClient response so we want to be selective about this
    @openai = AIBackend::OpenAI.new(
      users(:keith),
      @assistant,
      @conversation,
      @conversation.latest_message_for_version(:latest)
    )
    TestClient::OpenAI.new(access_token: "abc")
  end

  test "tools only passed when supported by the language model" do
    @assistant.language_model.update!(supports_tools: true)
    function = "openmeteo_get_current_and_todays_weather"
    streamed_text = ""

    TestClient::OpenAI.stub :function, function do
      @openai.stream_next_conversation_message { |chunk| streamed_text += chunk }
      assert_includes TestClient::OpenAI.parameters.keys, :tools
    end
  end

  test "tools not passed when not supported by the language model" do
    streamed_text = ""

    TestClient::OpenAI.stub :text, nil do
      @openai.stream_next_conversation_message { |chunk| streamed_text += chunk }
      assert_not_includes TestClient::OpenAI.parameters.keys, :tools
    end
  end

  test "stream_next_conversation_message works to get a function call" do
    @assistant.language_model.update!(supports_tools: true)
    function = "openmeteo_get_current_and_todays_weather"

    TestClient::OpenAI.stub :function, function do
      function_call = @openai.stream_next_conversation_message { |chunk| streamed_text += chunk }
      assert_equal function, function_call.dig(0, "function", "name")
    end
  end

  test "stream_next_conversation_message works to get a parallel function call CORRECTLY formatted" do
    @assistant.language_model.update!(supports_tools: true)
    function = "openmeteo_get_current_and_todays_weather"

    TestClient::OpenAI.stub :function, function do
      TestClient::OpenAI.stub :num_tool_calls, 2 do
        function_calls = @openai.stream_next_conversation_message { |chunk| streamed_text += chunk }

        assert_equal 2, function_calls.length
        assert_equal [0,1], function_calls.map { |f| f["index"] }
        assert_equal [function, function], function_calls.map { |f| f["function"]["name"] }
      end
    end
  end

  test "stream_next_conversation_message works to get a parallel function call INCORRECTLY formatted" do
    @assistant.language_model.update!(supports_tools: true)
    function = "openmeteo_get_current_and_todays_weather"
    arguments = {:city=>"Austin", :state=>"TX", :country=>"US"}.to_json

    TestClient::OpenAI.stub :function, function+function do
      TestClient::OpenAI.stub :arguments, arguments+arguments do
        TestClient::OpenAI.stub :id, "call_abccall_def" do
          function_calls = @openai.stream_next_conversation_message { |chunk| streamed_text += chunk }

          assert_equal 2, function_calls.length
          assert_equal [0,1], function_calls.map { |f| f[:index] }
          assert_equal ["call_abc", "call_def"], function_calls.map { |f| f[:id] }
          assert_equal [function, function], function_calls.map { |f| f[:function][:name] }
        end
      end
    end
  end
end
