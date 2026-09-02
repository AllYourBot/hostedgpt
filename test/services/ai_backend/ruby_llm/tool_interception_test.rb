require "test_helper"

class AIBackend::RubyLLM::ToolInterceptionTest < ActiveSupport::TestCase
  def build_tool
    AIBackend::RubyLLM::InterceptedTool.new(
      name: "get_weather",
      description: "Get the current weather for a location",
      params_schema: { type: "object", properties: { location: { type: "string" } } }
    )
  end

  def tool_call(id, location)
    RubyLLM::ToolCall.new(id: id, name: "get_weather", arguments: { location: location })
  end

  def build_chat
    chat = RubyLLM::Chat.new(model: "gpt-4o", provider: :openai, assume_model_exists: true)
    chat.add_message(role: :user, content: "What's the weather?")
    chat.with_tools(build_tool)
  end

  def stub_tool_call_response(chat, tool_calls, &)
    response = RubyLLM::Message.new(
      role: :assistant,
      content: nil,
      tool_calls: tool_calls.to_h { |tc| [tc.id, tc] }
    )
    chat.stub(:provider_completion, response, &)
  end

  test "chat.complete raises ToolCallIntercepted when the model requests a tool" do
    chat = build_chat

    assert_raises(AIBackend::RubyLLM::ToolCallIntercepted) do
      stub_tool_call_response(chat, [tool_call("call_abc123", "Austin")]) { chat.complete }
    end
  end

  test "every requested tool call is captured on the assistant message before the raise" do
    calls = [tool_call("call_abc123", "Austin"), tool_call("call_def456", "Boston")]
    chat = build_chat

    assert_raises(AIBackend::RubyLLM::ToolCallIntercepted) do
      stub_tool_call_response(chat, calls) { chat.complete }
    end

    last = chat.messages.last
    assert last.tool_call?, "the assistant message should carry tool calls"
    assert_equal calls.size, last.tool_calls.size

    assert_equal ["call_abc123", "call_def456"], last.tool_calls.values.map(&:id)
    assert_equal ["get_weather", "get_weather"], last.tool_calls.values.map(&:name)
    assert_equal ["Austin", "Boston"], last.tool_calls.values.map { |tc| tc.arguments[:location] }
  end

  test "execution halts cleanly: no tool result is appended and the chat does not auto-continue" do
    chat = build_chat

    assert_raises(AIBackend::RubyLLM::ToolCallIntercepted) do
      stub_tool_call_response(chat, [tool_call("call_abc123", "Austin")]) { chat.complete }
    end

    assert_empty chat.messages.select { |m| m.role == :tool },
      "no role: :tool result message should be appended"
    assert_equal 1, chat.messages.count { |m| m.role == :assistant },
      "the chat should not have auto-continued with a follow-up assistant message"
  end
end
