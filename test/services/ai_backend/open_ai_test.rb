require "test_helper"

class AIBackend::OpenAITest < ActiveSupport::TestCase
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

  test "initializing client works" do
    assert @openai.client.present?
  end

  test "openai url is properly set" do
    assert_equal "https://api.openai.com/v1/", @openai.client.uri_base
  end

  test "get_oneoff_message responds with a reply" do
    TestClient::OpenAI.stub :text, "Yes, I can hear you." do
      response = @openai.get_oneoff_message("I am a helpful assistant.", ["Can you hear me?"])
      assert_equal "Yes, I can hear you.", response
      assert_equal({:type=>"text"}, TestClient::OpenAI.parameters[:response_format])
    end
  end

  test "get_oneoff_message with response_format of json returns a hash" do
    TestClient::OpenAI.stub :text, "{\"response\":\"yes\"}" do
      response = @openai.get_oneoff_message("Reply with the JSON { response: 'yes' }", ["Give me the reply."], { response_format: { type: "json_object" } })
      assert_equal({"response"=>"yes"}, JSON.parse(response))
      assert_equal({:type=>"json_object"}, TestClient::OpenAI.parameters[:response_format])
    end
  end

  test "get_oneoff_message with intent shapes the exact expected request" do
    TestClient::OpenAI.stub :text, "{\"topic\":\"Rails collection counter\"}" do
      @openai.get_oneoff_message("Extract a topic.", ["Here is chat text."], json: true)

      params = TestClient::OpenAI.parameters

      assert_equal @assistant.language_model.api_name, params[:model]
      assert_equal({ type: "json_object" }, params[:response_format])
      assert_equal 2000, params[:max_completion_tokens]
      assert_nil params[:stream]
      assert_nil params[:stream_options]
      assert_not params.key?(:tools), "supports_tools is forced off in setup"
      assert_equal 2, params[:messages].length
      assert_equal "system", params[:messages][0][:role]
      assert_includes params[:messages][0][:content], "Extract a topic."
      assert_equal({ role: "user", content: "Here is chat text." }, params[:messages][1])
    end
  end

  test "explicit caller response_format still wins over internal intent" do
    TestClient::OpenAI.stub :text, "{}" do
      @openai.get_oneoff_message(
        "Try to get JSON.",
        ["some text"],
        { response_format: { type: "text" } },
        json: true
      )

      assert_equal({ type: "text" }, TestClient::OpenAI.parameters[:response_format])
    end
  end

  test "one-off provider calls are bounded in time" do
    slow_class = Class.new(TestClient::OpenAI) do
      define_method(:chat) do |**args|
        sleep 0.3
        super(**args)
      end
    end

    AIBackend::OpenAI.stub :client, slow_class do
      AIBackend::OpenAI.stub :oneoff_timeout_seconds, 0.05 do
        assert_equal 0.05, AIBackend::OpenAI.oneoff_timeout_seconds, "stub must apply"

        openai = AIBackend::OpenAI.new(users(:keith), @assistant, @conversation, @conversation.latest_message_for_version(:latest))

        error = assert_raises(Timeout::Error) do
          openai.get_oneoff_message("hi", ["there"])
        end

        assert_includes error.message, "execution expired"
      end
    end
  end

  test "a direct OpenAI subclass inherits json intent untouched" do
    subclass = Class.new(AIBackend::OpenAI)
    instance = subclass.new(users(:keith), @assistant, @conversation, @conversation.latest_message_for_version(:latest))

    TestClient::OpenAI.stub :text, "{\"topic\":\"Inherited\"}" do
      reply = instance.get_oneoff_message("Extract a topic.", ["Here is chat text."], json: true)

      params = TestClient::OpenAI.parameters
      assert_equal({ type: "json_object" }, params[:response_format])
      assert_equal @assistant.language_model.api_name, params[:model]
      assert_equal "Inherited", JSON.parse(reply)["topic"]
    end
  end

  test "stream_next_conversation_message works to stream text and uses model from assistant" do
    assert_not_equal @assistant, @conversation.assistant, "Should force this next message to use a different assistant so these don't match"

    TestClient::OpenAI.stub :text, nil do # this forces it to fall back to default text
      streamed_text = ""
      @openai.stream_next_conversation_message { |chunk| streamed_text += chunk }
      expected_start = "Hello this is model gpt-4o with instruction \"Note these additional items that you've been told and remembered:\\n\\nHe lives in Austin, Texas\\nHe owns a cat\\n\\nFor the user, the current time"
      expected_end = "\"! How can I assist you today?"
      assert streamed_text.start_with?(expected_start)
      assert streamed_text.end_with?(expected_end)
    end
  end

  test "get_tool_messages_by_calling properly executes tools" do
    tool_message = {
      role: "tool",
      content: "\"Hello, World!\"",
      tool_call_id: "abc123",
      content_tool_calls: messages(:weather_tool_call).content_tool_calls.first,
    }
    assert_equal [tool_message], AIBackend::OpenAI.get_tool_messages_by_calling(messages(:weather_tool_call).content_tool_calls)
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

  test "get_tool_messages_by_calling gracefully handles a failure within a function call" do
    tool_calls = messages(:weather_tool_call).content_tool_calls
    tool_calls[0][:function][:name] = "helloworld_bad"
    tool_calls[0][:function][:arguments].delete(:name)

    msg = AIBackend::OpenAI.get_tool_messages_by_calling(tool_calls).first
    assert_equal "tool", msg[:role]
    assert_equal "abc123", msg[:tool_call_id]
    assert msg[:content].starts_with?('"An unexpected error occurred')
  end

  test "get_tool_messages_by_calling gracefully handles calling an invalid function" do
    tool_calls = messages(:weather_tool_call).content_tool_calls
    tool_calls[0][:function][:name] = "helloworld_nonexistent"
    tool_calls[0][:function][:arguments].delete(:name)

    msg = AIBackend::OpenAI.get_tool_messages_by_calling(tool_calls).first
    assert_equal "tool", msg[:role]
    assert_equal "abc123", msg[:tool_call_id]
    assert msg[:content].starts_with?('"An unexpected error occurred')
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

  test "preceding_conversation_messages constructs a proper response and pivots on images" do
    preceding_conversation_messages = @openai.send(:preceding_conversation_messages)

    assert_equal @conversation.messages.length-1, preceding_conversation_messages.length

    @conversation.messages.ordered.each_with_index do |message, i|
      next if @conversation.messages.length == i+1

      if message.documents.present?
        assert_instance_of Array, preceding_conversation_messages[i][:content]
        assert_equal message.documents.length+1, preceding_conversation_messages[i][:content].length
      else
        assert_equal preceding_conversation_messages[i][:content], message.content_text
      end
    end
  end

  test "preceding_conversation_messages only considers messages on the intended conversation version and includes the correct names" do
    message = messages(:message3_v1)
    conversation = message.conversation
    assistant = message.assistant
    user = message.user
    version = message.version
    @openai = AIBackend::OpenAI.new(user, assistant, conversation, message)

    preceding_conversation_messages = @openai.send(:preceding_conversation_messages)
    convo_messages = conversation.messages.for_conversation_version(version).where("messages.index < ?", message.index)

    assert_equal convo_messages.map(&:content_text), preceding_conversation_messages.map { |m| m[:content] }
    assert_equal user.first_name, preceding_conversation_messages.first[:name]
    assert_equal assistant.name, preceding_conversation_messages.second[:name]
  end

  test "preceding_conversation_messages includes the appropriate tool details" do
    message = messages(:weather_explained)
    conversation = message.conversation
    assistant = message.assistant
    user = message.user
    version = message.version
    @openai = AIBackend::OpenAI.new(user, assistant, conversation, message)

    messages = @openai.send(:preceding_conversation_messages)

    m1 = {:role=>"user", :name=>"Keith", :content=>"What is the weather in Austin?"}
    m2 = {:role=>"assistant", :name=>"Samantha", :tool_calls=>[{:id=>"abc123", :type=>"function", :index=>0, :function=>{:name=>"helloworld_hi", :arguments=>{:name=>"World"}}}]}
    m3 = {:role=>"tool", :content=>"weather is", :tool_call_id=>"abc123"}

    assert_equal m1, messages.first
    assert_equal m2, messages.second
    assert_equal m3, messages.third
  end
end

class AIBackend::OpenAIImageTest < ActiveSupport::TestCase
  test "generate_image calls the images API with expected parameters and returns the payload" do
    response = AIBackend::OpenAI.generate_image(prompt: "A cartoon cat", user: users(:keith))

    assert_equal "TEST_BASE64_IMAGE_DATA", response[:b64_json]
    assert_equal "gpt-image-1", response[:model]

    params = TestClient::OpenAI.images.parameters
    assert_equal "A cartoon cat", params[:prompt]
    assert_equal "gpt-image-1", params[:model]
    assert_equal 1, params[:n]
    assert_equal "1024x1024", params[:size]
    assert_equal "auto", params[:quality]
  end

  test "generate_image raises the preserved message when the user has no OpenAI service" do
    users(:keith).api_services.update_all(deleted_at: Time.current) # rubocop:disable Rails/SkipsModelValidations

    Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
      error = assert_raises(RuntimeError) { AIBackend::OpenAI.generate_image(prompt: "A cartoon cat", user: users(:keith)) }
      expected_backend = messages(:image_generation_tool_call).assistant.language_model.api_service.name
      assert_equal "OpenAI API key not found. Image generation requires an OpenAI API key. Please configure your OpenAI API key in Settings > API Services to use image generation with #{expected_backend}.", error.message
    end
  end

  test "backends without native image generation delegate to OpenAI" do
    AIBackend::OpenAI.stub :generate_image, { b64_json: "DELEGATED", model: "gpt-image-1" } do
      result = AIBackend::Anthropic.generate_image(prompt: "A cartoon cat", user: users(:keith))
      assert_equal "DELEGATED", result[:b64_json]
    end
  end
end
