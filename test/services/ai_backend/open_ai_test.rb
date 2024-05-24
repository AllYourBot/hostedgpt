require "test_helper"

class AIBackend::OpenAITest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:attachments)
    @assistant = assistants(:keith_claude3)
    @openai = AIBackend::OpenAI.new(
      users(:keith),
      @assistant,
      @conversation,
      @conversation.latest_message_for_version(:latest)
    )
    @test_client = TestClient::OpenAI.new(access_token: 'abc')
  end

  test "initializing client works" do
    assert @openai.client.present?
  end

  test "get_next_chat_message works to stream text and uses model from assistant" do
    assert_not_equal @assistant, @conversation.assistant,
      "We want to force this next message to use a different assistant so these should not match"

    TestClient::OpenAI.stub :text, nil do # this forces it to fall back to default text
      TestClient::OpenAI.stub :api_response, -> { TestClient::OpenAI.api_text_response }do
        streamed_text = ""
        @openai.get_next_chat_message { |chunk| streamed_text += chunk }
        assert_equal "Hello this is model claude-3-opus-20240229 with instruction nil! How can I assist you today?", streamed_text
      end
    end
  end

  test "get_tool_messages_by_calling properly executes tools" do
    tool_message = {
      role: "tool",
      content: "\"Hello, World!\"",
      tool_call_id: "abc123",
    }
    assert_equal [tool_message], AIBackend::OpenAI.get_tool_messages_by_calling(messages(:weather_tool_call).content_tool_calls)
  end

  test "get_tool_messages_by_calling gracefully handles a failure within a function call" do
    tool_calls = messages(:weather_tool_call).content_tool_calls
    tool_calls[0][:function][:name] = "helloworld_bad"
    tool_calls[0][:function][:arguments].delete(:name)

    msg = AIBackend::OpenAI.get_tool_messages_by_calling(tool_calls).first
    assert_equal "tool", msg[:role]
    assert_equal "abc123", msg[:tool_call_id]
    assert msg[:content].starts_with?('"An unexpected error occurred. You')
  end

  test "get_tool_messages_by_calling gracefully handles calling an invalid function" do
    tool_calls = messages(:weather_tool_call).content_tool_calls
    tool_calls[0][:function][:name] = "helloworld_nonexistent"
    tool_calls[0][:function][:arguments].delete(:name)

    msg = AIBackend::OpenAI.get_tool_messages_by_calling(tool_calls).first
    assert_equal "tool", msg[:role]
    assert_equal "abc123", msg[:tool_call_id]
    assert msg[:content].starts_with?('"An unexpected error occurred. You')
  end

  test "get_next_chat_message works to get a function call" do
    function = "openmeteo_get_current_and_todays_weather"

    TestClient::OpenAI.stub :function, function do
      TestClient::OpenAI.stub :api_response, TestClient::OpenAI.api_function_response do
        function_call = @openai.get_next_chat_message { |chunk| streamed_text += chunk }
        assert_equal function, function_call.dig(0, "function", "name")
      end
    end
  end

  test "preceding_messages constructs a proper response and pivots on images" do
    preceding_messages = @openai.send(:preceding_messages)

    assert_equal @conversation.messages.length-1, preceding_messages.length

    @conversation.messages.ordered.each_with_index do |message, i|
      next if @conversation.messages.length == i+1

      if message.documents.present?
        assert_instance_of Array, preceding_messages[i][:content]
        assert_equal message.documents.length+1, preceding_messages[i][:content].length
      else
        assert_equal preceding_messages[i][:content], message.content_text
      end
    end
  end

  test "preceding_messages only considers messages on the intended conversation version and includes the correct names" do
    message = messages(:message3_v1)
    conversation = message.conversation
    assistant = message.assistant
    user = message.user
    version = message.version
    @openai = AIBackend::OpenAI.new(user, assistant, conversation, message)

    preceding_messages = @openai.send(:preceding_messages)
    convo_messages = conversation.messages.for_conversation_version(version).where("messages.index < ?", message.index)

    assert_equal convo_messages.map(&:content_text), preceding_messages.map { |m| m[:content] }
    assert_equal user.first_name, preceding_messages.first[:name]
    assert_equal assistant.name, preceding_messages.second[:name]
  end

  test "preceding_messages includes the appropriate tool details" do
    message = messages(:weather_explained)
    conversation = message.conversation
    assistant = message.assistant
    user = message.user
    version = message.version
    @openai = AIBackend::OpenAI.new(user, assistant, conversation, message)

    messages = @openai.send(:preceding_messages)

    m1 = {:role=>"user", :name=>"Keith", :content=>"What is the weather in Austin?"}
    m2 = {:role=>"assistant", :name=>"Samantha", :tool_calls=>[{:id=>"abc123", :type=>"function", :index=>0, :function=>{:name=>"helloworld_hi", :arguments=>{:name=>"World"}}}]}
    m3 = {:role=>"tool", :content=>"weather is", :tool_call_id=>"abc123"}

    assert_equal m1, messages.first
    assert_equal m2, messages.second
    assert_equal m3, messages.third
  end
end
