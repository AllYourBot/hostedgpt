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
    TestClient::OpenAI.reset_recordings!
  end

  test "initializing client works" do
    assert @openai.client.present?
  end

  test "recordings start clean in every example" do
    assert_nil TestClient::OpenAI.parameters
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
      expected = "Hello this is model gpt-4o with instruction \"Note these additional items that you've been told and remembered:\\n\\nHe lives in Austin, Texas\\nHe owns a cat\"! How can I assist you today?"
      assert_equal expected, streamed_text
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
    history = @conversation.messages.ordered.to_a[0...-1]
    newest_user_message = history.select(&:user?).last

    assert_equal history.length, preceding_conversation_messages.length

    history.zip(preceding_conversation_messages).each do |message, sent|
      if message.documents.present?
        time_note = message == newest_user_message ? 1 : 0
        assert_instance_of Array, sent[:content]
        assert_equal message.documents.length + 1 + time_note, sent[:content].length
      else
        assert sent[:content].start_with?(message.content_text)
      end
    end
  end

  test "preceding_conversation_messages keeps a text-only newest user message as a string with the time appended" do
    conversation = Conversation.create!(user: users(:keith), assistant: @assistant, title: "Plain")
    conversation.messages.create!(role: "user", content_text: "Hello", assistant: @assistant)
    reply = conversation.messages.create!(role: "assistant", content_text: "Hi", assistant: @assistant)
    backend = AIBackend::OpenAI.new(users(:keith), @assistant, conversation, reply)

    newest = backend.stub(:current_time_note, "NOTE") { backend.send(:preceding_conversation_messages).first }

    assert_equal "Hello\n\nNOTE", newest[:content]
  end

  test "preceding_conversation_messages attaches the assistant's context images to the first user message only" do
    @assistant.language_model.update!(supports_images: true)
    @assistant.documents.create!(file: Rack::Test::UploadedFile.new(file_fixture("cat.png"), "image/png"))
    conversation = Conversation.create!(user: users(:keith), assistant: @assistant, title: "Context")
    conversation.messages.create!(role: "user", content_text: "Hello", assistant: @assistant)
    conversation.messages.create!(role: "assistant", content_text: "Hi", assistant: @assistant)
    conversation.messages.create!(role: "user", content_text: "What is in the picture?", assistant: @assistant)
    reply = conversation.messages.create!(role: "assistant", content_text: "", assistant: @assistant)
    backend = AIBackend::OpenAI.new(users(:keith), @assistant, conversation, reply)

    first_user, _reply, newest_user = backend.send(:preceding_conversation_messages)

    assert_equal [{ type: "text", text: "Hello" }], first_user[:content].first(1), "The user's own text should come first"
    assert first_user[:content].second[:image_url][:url].start_with?("data:image/png;base64,"), "The context image should ride on the first user message"
    assert_instance_of String, newest_user[:content], "Later messages should stay text-only"
  end

  test "preceding_conversation_messages sends a PDF as a file part when the model supports PDFs" do
    @assistant.language_model.update!(supports_pdf: true)
    backend = backend_replying_to_pdf

    part = backend.send(:preceding_conversation_messages).first[:content].find { |p| p[:type] == "file" }

    assert_equal "quarterly.pdf", part[:file][:filename]
    assert_equal "data:application/pdf;base64,#{Base64.strict_encode64(file_fixture("quarterly.pdf").binread)}", part[:file][:file_data]
  end

  test "preceding_conversation_messages sends a PDF's text to a model without PDF or image support" do
    @assistant.language_model.update!(supports_pdf: false, supports_images: false)
    backend = backend_replying_to_pdf

    content = backend.send(:preceding_conversation_messages).first[:content]

    assert_instance_of String, content
    assert_includes content, "[PDF Document: quarterly.pdf]\nQuarterly numbers"
  end

  test "preceding_conversation_messages only considers messages on the intended conversation version and includes the correct names" do
    message = messages(:message3_v1)
    conversation = message.conversation
    assistant = message.assistant
    user = message.user
    version = message.version
    @openai = AIBackend::OpenAI.new(user, assistant, conversation, message)

    preceding_conversation_messages = @openai.stub(:current_time_note, "NOTE") { @openai.send(:preceding_conversation_messages) }
    convo_messages = conversation.messages.for_conversation_version(version).where("messages.index < ?", message.index).to_a
    newest_user_message = convo_messages.select(&:user?).last
    expected = convo_messages.map { |m| m == newest_user_message ? "#{m.content_text}\n\nNOTE" : m.content_text }

    assert_equal expected, preceding_conversation_messages.map { |m| m[:content] }
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

    messages = @openai.stub(:current_time_note, "NOTE") { @openai.send(:preceding_conversation_messages) }

    m1 = {:role=>"user", :name=>"Keith", :content=>"What is the weather in Austin?\n\nNOTE"}
    m2 = {:role=>"assistant", :name=>"Samantha", :tool_calls=>[{:id=>"abc123", :type=>"function", :index=>0, :function=>{:name=>"helloworld_hi", :arguments=>{:name=>"World"}}}]}
    m3 = {:role=>"tool", :content=>"weather is", :tool_call_id=>"abc123"}

    assert_equal m1, messages.first
    assert_equal m2, messages.second
    assert_equal m3, messages.third
  end

  test "key_error_message returns the recorded OpenAI copy" do
    assert_equal "(You need to enter a valid API key for OpenAI to use GPT. Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find OpenAI Key instructions.)",
      AIBackend::OpenAI.key_error_message
  end

  test "billing_url returns the recorded OpenAI billing page" do
    assert_equal "https://platform.openai.com/account/billing/overview", AIBackend::OpenAI.billing_url
  end

  private

  def backend_replying_to_pdf
    conversation = Conversation.create!(user: users(:keith), assistant: @assistant, title: "PDF Test Conversation")
    message = conversation.messages.create!(role: "user", content_text: "Please analyze this PDF", assistant: @assistant)
    message.documents.create!(file: { io: StringIO.new(file_fixture("quarterly.pdf").binread), filename: "quarterly.pdf", content_type: "application/pdf" })
    reply = conversation.messages.create!(role: "assistant", content_text: "I'll analyze the PDF for you", assistant: @assistant)

    AIBackend::OpenAI.new(users(:keith), @assistant, conversation, reply)
  end
end

class AIBackend::OpenAISpeechTest < ActiveSupport::TestCase
  test "generate_speech calls the audio API with expected parameters and returns the audio" do
    audio = AIBackend::OpenAI.generate_speech(text: "Hello there", user: users(:keith))

    assert_equal "TEST_WAV_BYTES", audio

    params = TestClient::OpenAI.audio.parameters
    assert_equal "Hello there", params[:input]
    assert_equal "tts-1", params[:model]
    assert_equal "nova", params[:voice]
    assert_equal "wav", params[:response_format]
  end

  test "generate_speech requires the canonical OpenAI service" do
    api_services(:keith_openai_service).update!(deleted_at: Time.current)

    assert_raises(AIBackend::ConfigurationError) do
      AIBackend::OpenAI.generate_speech(text: "Hello there", user: users(:keith))
    end
  end
end

class AIBackend::OpenAIImageTest < ActiveSupport::TestCase
  test "generate_image calls the images API with expected parameters and returns the payload" do
    response = AIBackend::OpenAI.generate_image(prompt: "A cartoon cat", user: users(:keith))

    assert_equal "TEST_BASE64_IMAGE_DATA", response[:b64_json]
    assert_equal "gpt-image-1", response[:model]
    assert_equal "OpenAI", response[:provider]

    params = TestClient::OpenAI.images.parameters
    assert_equal "A cartoon cat", params[:prompt]
    assert_equal "gpt-image-1", params[:model]
    assert_equal 1, params[:n]
    assert_equal "1024x1024", params[:size]
    assert_equal "auto", params[:quality]
  end

  test "generate_image raises a context-free message when the user has no OpenAI service" do
    users(:keith).api_services.update_all(deleted_at: Time.current) # rubocop:disable Rails/SkipsModelValidations

    error = assert_raises(RuntimeError) { AIBackend::OpenAI.generate_image(prompt: "A cartoon cat", user: users(:keith)) }
    assert_equal "OpenAI API key not found. Image generation requires an OpenAI API key. Please configure your OpenAI API key in Settings > API Services", error.message
    assert_not error.message.include?("to use image generation with") # the toolbox owns that context, not the provider layer
  end

  test "generate_image ignores Groq and OpenRouter rows and requires the canonical OpenAI service" do
    # Groq and OpenRouter services also carry driver :openai; their tokens are
    # invalid at api.openai.com, so only the canonical URL may satisfy the lookup.
    api_services(:keith_openai_service).update!(deleted_at: Time.current)

    error = assert_raises(RuntimeError) { AIBackend::OpenAI.generate_image(prompt: "A cartoon cat", user: users(:keith)) }
    assert_includes error.message, "OpenAI API key not found"
  end

  test "backends without native image generation delegate to OpenAI" do
    AIBackend::OpenAI.stub :generate_image, { b64_json: "DELEGATED", model: "gpt-image-1", provider: "OpenAI" } do
      result = AIBackend::Anthropic.generate_image(prompt: "A cartoon cat", user: users(:keith))
      assert_equal "DELEGATED", result[:b64_json]
    end
  end
end
