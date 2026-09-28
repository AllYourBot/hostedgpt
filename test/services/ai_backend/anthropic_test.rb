require "test_helper"

class AIBackend::AnthropicTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile
  setup do
    @conversation = conversations(:hello_claude)
    @assistant = assistants(:keith_claude35)
    @assistant.language_model.update!(supports_tools: false) # this will change the TestClient response so we want to be selective about this
    @anthropic = AIBackend::Anthropic.new(
      users(:keith),
      @assistant,
      @conversation,
      @conversation.latest_message_for_version(:latest)
    )
    TestClient::Anthropic.new(access_token: "abc")
    TestClient::Anthropic.reset_recordings!
  end

  test "initializing client works" do
    assert @anthropic.client.present?
  end

  test "stream_next_conversation_message works to stream text and uses model from assistant" do
    assert_not_equal @assistant, @conversation.assistant, "Should force this next message to use a different assistant so these don't match"

    TestClient::Anthropic.stub :text, nil do # this forces it to fall back to default text
      streamed_text = ""
      @anthropic.stream_next_conversation_message { |chunk| streamed_text += chunk }
      expected = "Hello this is model claude-3-5-sonnet-20240620 with instruction \"Note these additional items that you've been told and remembered:\\n\\nHe lives in Austin, Texas\\nHe owns a cat\"! How can I assist you today?"
      assert_equal expected, streamed_text
    end
  end

  test "stream_next_conversation_message sends the instructions as one cached system block" do
    @anthropic.stream_next_conversation_message { |chunk| }

    system = TestClient::Anthropic.messages_args.dig(:parameters, :system)
    assert_equal 1, system.length
    assert_includes system.first[:text], "He owns a cat"
    assert_equal({ type: "ephemeral" }, system.first[:cache_control])
  end

  test "preceding_conversation_messages puts the current time on the newest user message only" do
    first_user, _reply, newest_user = @anthropic.send(:preceding_conversation_messages)

    assert_equal "Hi Claude, can you hear me?", first_user[:content]
    assert_equal "How old are you?", newest_user[:content].first[:text]
    assert_includes newest_user[:content].last[:text], "For the user, the current time is"
    refute newest_user[:content].any? { |block| block[:cache_control] }, "The time note changes every turn, so nothing after it should be cached"
  end

  test "preceding_conversation_messages ends the cacheable prefix at the reply before the newest user message" do
    messages = @anthropic.send(:preceding_conversation_messages)

    assert_equal 3, messages.length
    assert_equal [{ type: "text", text: "Yes, I can hear you.", cache_control: { type: "ephemeral" } }], messages[1][:content]
  end

  test "anthropic_format_tools converts OpenAI format to Anthropic format" do
    openai_tools = [
      {
        type: "function",
        function: {
          name: "get_weather",
          description: "Get the current weather",
          parameters: {
            type: "object",
            properties: {
              location: { type: "string" },
              units: { type: "string", enum: ["celsius", "fahrenheit"] }
            },
            required: ["location"]
          }
        }
      }
    ]

    result = @anthropic.send(:anthropic_format_tools, openai_tools)

    assert_equal 1, result.length
    assert_equal "get_weather", result[0][:name]
    assert_equal "Get the current weather", result[0][:description]
    assert_equal "object", result[0][:input_schema][:type]
    assert_equal({ location: { type: "string" }, units: { type: "string", enum: ["celsius", "fahrenheit"] } }, result[0][:input_schema][:properties])
    assert_equal ["location"], result[0][:input_schema][:required]
  end

  test "anthropic_format_tools handles multiple tools" do
    openai_tools = [
      {
        type: "function",
        function: {
          name: "tool1",
          description: "First tool",
          parameters: { type: "object", properties: {}, required: [] }
        }
      },
      {
        type: "function",
        function: {
          name: "tool2",
          description: "Second tool",
          parameters: { type: "object", properties: {}, required: [] }
        }
      }
    ]

    result = @anthropic.send(:anthropic_format_tools, openai_tools)

    assert_equal 2, result.length
    assert_equal "tool1", result[0][:name]
    assert_equal "tool2", result[1][:name]
  end

  test "anthropic_format_tools returns empty array for nil tools" do
    assert_equal [], @anthropic.send(:anthropic_format_tools, nil)
  end

  test "anthropic_format_tools returns empty array for empty tools" do
    assert_equal [], @anthropic.send(:anthropic_format_tools, [])
  end

  test "anthropic_format_tools handles missing parameters with defaults" do
    openai_tools = [
      {
        type: "function",
        function: {
          name: "simple_tool",
          description: "Simple tool"
        }
      }
    ]

    result = @anthropic.send(:anthropic_format_tools, openai_tools)

    assert_equal 1, result.length
    assert_equal "object", result[0][:input_schema][:type]
    assert_equal({}, result[0][:input_schema][:properties])
    assert_equal [], result[0][:input_schema][:required]
  end

  test "anthropic_format_tools handles malformed tools gracefully" do
    openai_tools = [
      { not_a: "valid_tool" }
    ]

    result = @anthropic.send(:anthropic_format_tools, openai_tools)
    assert_equal [], result
  end

  test "handle_tool_use_streaming initializes tool call on content_block_start" do
    @anthropic.instance_variable_set(:@stream_response_tool_calls, {})

    intermediate_response = {
      "type" => "content_block_start",
      "index" => 0,
      "content_block" => {
        "type" => "tool_use",
        "id" => "toolu_123",
        "name" => "get_weather"
      }
    }

    @anthropic.send(:handle_tool_use_streaming, intermediate_response)

    tool_calls = @anthropic.instance_variable_get(:@stream_response_tool_calls)
    assert_equal "toolu_123", tool_calls[0]["id"]
    assert_equal "get_weather", tool_calls[0]["name"]
    assert_equal({}, tool_calls[0]["input"])
  end

  test "handle_tool_use_streaming accumulates JSON deltas" do
    @anthropic.instance_variable_set(:@stream_response_tool_calls, {
      0 => { "id" => "toolu_123", "name" => "get_weather", "input" => {} }
    })

    delta1 = {
      "type" => "content_block_delta",
      "index" => 0,
      "delta" => {
        "type" => "input_json_delta",
        "partial_json" => '{"location":'
      }
    }

    delta2 = {
      "type" => "content_block_delta",
      "index" => 0,
      "delta" => {
        "type" => "input_json_delta",
        "partial_json" => ' "Austin"}'
      }
    }

    @anthropic.send(:handle_tool_use_streaming, delta1)
    tool_calls = @anthropic.instance_variable_get(:@stream_response_tool_calls)
    assert_equal '{"location":', tool_calls[0]["_partial_json"]

    @anthropic.send(:handle_tool_use_streaming, delta2)
    tool_calls = @anthropic.instance_variable_get(:@stream_response_tool_calls)
    assert_equal '{"location": "Austin"}', tool_calls[0]["_partial_json"]
    assert_equal({ "location" => "Austin" }, tool_calls[0]["input"])
  end

  test "handle_tool_use_streaming handles incomplete JSON" do
    @anthropic.instance_variable_set(:@stream_response_tool_calls, {
      0 => { "id" => "toolu_123", "name" => "get_weather", "input" => {} }
    })

    delta = {
      "type" => "content_block_delta",
      "index" => 0,
      "delta" => {
        "type" => "input_json_delta",
        "partial_json" => '{"location":'
      }
    }

    @anthropic.send(:handle_tool_use_streaming, delta)

    tool_calls = @anthropic.instance_variable_get(:@stream_response_tool_calls)
    assert_equal '{"location":', tool_calls[0]["_partial_json"]
    assert_equal({}, tool_calls[0]["input"]) # Should remain empty until valid JSON
  end

  test "handle_tool_use_streaming cleans up on content_block_stop" do
    @anthropic.instance_variable_set(:@stream_response_tool_calls, {
      0 => { "id" => "toolu_123", "name" => "get_weather", "input" => { "location" => "Austin" }, "_partial_json" => '{"location": "Austin"}' }
    })

    stop = {
      "type" => "content_block_stop",
      "index" => 0
    }

    @anthropic.send(:handle_tool_use_streaming, stop)

    tool_calls = @anthropic.instance_variable_get(:@stream_response_tool_calls)
    assert_nil tool_calls[0]["_partial_json"]
    assert_equal({ "location" => "Austin" }, tool_calls[0]["input"])
  end

  test "preceding_conversation_messages converts tool role to user with tool_result" do
    conversation = conversations(:weather)
    message = messages(:weather_explained)
    @anthropic = AIBackend::Anthropic.new(users(:keith), message.assistant, conversation, message)

    messages = @anthropic.send(:preceding_conversation_messages)

    tool_result_message = messages.find { |m| m[:role] == "user" && m[:content].is_a?(Array) && m[:content].first[:type] == "tool_result" }
    assert tool_result_message, "Should find a tool_result message"
    assert_equal "user", tool_result_message[:role]
    assert_equal "tool_result", tool_result_message[:content][0][:type]
    assert_equal "abc123", tool_result_message[:content][0][:tool_use_id]
    assert_equal "weather is", tool_result_message[:content][0][:content]
  end

  test "preceding_conversation_messages converts assistant message with tool_calls" do
    conversation = conversations(:weather)
    message = messages(:weather_explained)
    @anthropic = AIBackend::Anthropic.new(users(:keith), message.assistant, conversation, message)

    messages = @anthropic.send(:preceding_conversation_messages)

    assistant_msg = messages.find { |m| m[:role] == "assistant" && m[:content].is_a?(Array) }
    assert assistant_msg, "Should find assistant message with content array"

    tool_use = assistant_msg[:content].find { |c| c[:type] == "tool_use" }
    assert tool_use, "Should find tool_use in content"
    assert_equal "abc123", tool_use[:id]
    assert_equal "helloworld_hi", tool_use[:name]
    assert_equal({ name: "World" }, tool_use[:input])
  end

  test "tools only passed when supported by the language model" do
    @assistant.language_model.update!(supports_tools: true)
    @anthropic.instance_variable_set(:@response_handler, proc {})

    @anthropic.send(:set_client_config, {
      instructions: "Test",
      messages: [],
      streaming: true,
      params: {}
    })

    config = @anthropic.instance_variable_get(:@client_config)
    assert config[:tools].present?, "Tools should be present in config"
    assert config[:parameters][:tools].present?, "Tools should be present in parameters"
  end

  test "tools not passed when not supported by the language model" do
    @assistant.language_model.update!(supports_tools: false)
    @anthropic.instance_variable_set(:@response_handler, proc {})

    @anthropic.send(:set_client_config, {
      instructions: "Test",
      messages: [],
      streaming: true,
      params: {}
    })

    config = @anthropic.instance_variable_get(:@client_config)
    assert_nil config[:tools], "Tools should not be present in config"
    assert_nil config[:parameters][:tools], "Tools should not be present in parameters"
  end

  test "stream_next_conversation_message works to get a tool call" do
    @assistant.language_model.update!(supports_tools: true)

    TestClient::Anthropic.stub :function, "openmeteo_get_current_and_todays_weather" do
      tool_calls = @anthropic.stream_next_conversation_message { |chunk| }
      assert_equal "openmeteo_get_current_and_todays_weather", tool_calls.dig(0, :function, :name)
    end
  end

  test "preceding_conversation_messages sends a PDF natively and caches it when the model supports PDFs" do
    @assistant.language_model.update!(supports_pdf: true)
    backend = backend_replying_to_pdf("report.pdf", "%PDF-1.4 native bytes")

    pdf_message = backend.send(:preceding_conversation_messages).first
    document = pdf_message[:content].find { |block| block[:type] == "document" }

    assert_equal "Please analyze this PDF", pdf_message[:content].first[:text]
    assert_equal({ type: "base64", media_type: "application/pdf", data: Base64.strict_encode64("%PDF-1.4 native bytes") }, document[:source])
    assert_equal({ type: "ephemeral" }, document[:cache_control])
  end

  test "preceding_conversation_messages falls back to the PDF's text when the model cannot read PDFs, even without image support" do
    @assistant.language_model.update!(supports_pdf: false, supports_images: false)
    backend = backend_replying_to_pdf("quarterly.pdf", file_fixture("quarterly.pdf").binread)

    pdf_message = backend.send(:preceding_conversation_messages).first

    assert_includes pdf_message[:content].pluck(:text), "[PDF Document: quarterly.pdf]\nQuarterly numbers"
    refute pdf_message[:content].any? { |block| block[:type] == "document" }
  end

  test "preceding_conversation_messages says so when a PDF's text cannot be extracted" do
    @assistant.language_model.update!(supports_pdf: false)
    backend = backend_replying_to_pdf("corrupted.pdf", "%PDF-1.4\ncorrupted content")

    pdf_message = backend.send(:preceding_conversation_messages).first

    assert_includes pdf_message[:content].pluck(:text), "[PDF Document: corrupted.pdf - Unable to extract text from this PDF]"
  end

  test "one-off messages call records arguments and returns a diggable envelope" do
    response = TestClient::Anthropic.new(access_token: "abc").messages(
      model: "claude-x", parameters: { system: "be terse" }
    )

    assert_instance_of Hash, response
    assert_equal "be terse", TestClient::Anthropic.messages_args.dig(:parameters, :system)
    assert response.dig("content", 0, "text").present?
  end

  test "json intent suffix coerces mechanism without promising a topic schema" do
    @anthropic.send(:set_client_config, { instructions: "Extract a topic.", messages: [], json: true })
    suffix = @anthropic.instance_variable_get(:@client_config)[:system].split("\n\n").last

    assert_includes suffix, "ONLY valid JSON"
    refute_includes suffix, "topic"
  end

  test "one-off with json intent appends the exact suffix to both system slots and never sends response_format" do
    suffix = "\n\nIMPORTANT: You must respond with ONLY valid JSON. Do not include any explanatory text, markdown formatting, or other content."

    TestClient::Anthropic.stub :text, "{\"topic\":\"Claude Notes\"}" do
      reply = @anthropic.get_oneoff_message("Extract a topic.", ["Here is chat text."], json: true)
      args = TestClient::Anthropic.messages_args

      assert_equal "Claude Notes", JSON.parse(reply)["topic"]
      assert args[:system].end_with?(suffix)
      assert args.dig(:parameters, :system).end_with?(suffix)
      assert_equal args[:system], args.dig(:parameters, :system), "outer and inner system slots carry identical bytes"
      assert_nil args[:response_format]
      assert_nil args.dig(:parameters, :response_format)
    end
  end

  test "one-off without json intent leaves instructions unsuffixed while params strip persists" do
    TestClient::Anthropic.stub :text, "plain answer" do
      reply = @anthropic.get_oneoff_message(
        "Just answer.",
        ["some text"],
        { model: "claude-override", response_format: { type: "json_object" } }
      )
      args = TestClient::Anthropic.messages_args

      assert_not args[:system].end_with?("ONLY valid JSON")
      assert_not args.dig(:parameters, :system).end_with?("ONLY valid JSON")
      assert_includes args[:system], "Just answer."
      assert_nil args.dig(:parameters, :response_format), "foreign keys stay stripped from transmitted parameters"
      assert_equal "claude-override", args.dig(:parameters, :model), "explicit caller params still win"
      assert_equal "plain answer", reply
    end
  end

  test "key_error_message returns the recorded Anthropic copy" do
    assert_equal "(You need to enter a valid API key for Anthropic to use Claude. Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find Anthropic Key instructions.)",
      AIBackend::Anthropic.key_error_message
  end

  test "billing_url returns the recorded Anthropic billing page" do
    assert_equal "https://console.anthropic.com/settings/plans", AIBackend::Anthropic.billing_url
  end

  private

  def backend_replying_to_pdf(filename, pdf_bytes)
    conversation = Conversation.create!(user: users(:keith), assistant: @assistant, title: "PDF Test Conversation")
    message = conversation.messages.create!(role: "user", content_text: "Please analyze this PDF", assistant: @assistant)
    message.documents.create!(file: { io: StringIO.new(pdf_bytes), filename:, content_type: "application/pdf" })
    reply = conversation.messages.create!(role: "assistant", content_text: "I'll analyze the PDF for you", assistant: @assistant)

    AIBackend::Anthropic.new(users(:keith), @assistant, conversation, reply)
  end
end
