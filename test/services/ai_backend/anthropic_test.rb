require "test_helper"

class AIBackend::AnthropicTest < ActiveSupport::TestCase
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
  end

  test "initializing client works" do
    assert @anthropic.client.present?
  end

  test "stream_next_conversation_message works to stream text and uses model from assistant" do
    assert_not_equal @assistant, @conversation.assistant, "Should force this next message to use a different assistant so these don't match"

    TestClient::Anthropic.stub :text, nil do # this forces it to fall back to default text
      streamed_text = ""
      @anthropic.stream_next_conversation_message { |chunk| streamed_text += chunk }
      expected_start = "Hello this is model claude-3-5-sonnet-20240620 with instruction \"Note these additional items that you've been told and remembered:\\n\\nHe lives in Austin, Texas\\nHe owns a cat\\n\\nFor the user, the current time"
      expected_end = "\"! How can I assist you today?"
      assert streamed_text.start_with?(expected_start)
      assert streamed_text.end_with?(expected_end)
    end
  end

  test "preceding_conversation_messages constructs a proper response and pivots on images" do
    preceding_conversation_messages = @anthropic.send(:preceding_conversation_messages)

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
end
