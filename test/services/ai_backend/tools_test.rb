require "test_helper"

class AIBackend::ToolsTest < ActiveSupport::TestCase
  test "get_tool_messages_by_calling properly executes tools" do
    tool_message = {
      role: "tool",
      content: "\"Hello, World!\"",
      tool_call_id: "abc123",
      content_tool_calls: messages(:weather_tool_call).content_tool_calls.first,
    }
    assert_equal [tool_message], AIBackend.get_tool_messages_by_calling(messages(:weather_tool_call).content_tool_calls)
  end

  test "get_tool_messages_by_calling gracefully handles a failure within a function call" do
    tool_calls = messages(:weather_tool_call).content_tool_calls
    tool_calls[0][:function][:name] = "helloworld_get_eligibility"
    tool_calls[0][:function][:arguments] = { birthdate: "2000-01-01", gender: "male" }

    msg = AIBackend::RubyLLM.get_tool_messages_by_calling(tool_calls).first
    assert_equal "tool", msg[:role], "The result should still be a tool message"
    assert_equal "abc123", msg[:tool_call_id], "The result should answer the call it was for"
    assert_equal tool_calls.first, msg[:content_tool_calls], "The original call should travel with the result"
    assert msg[:content].starts_with?('"An unexpected error occurred'), "The model should get the friendly error text"
  end

  test "get_tool_messages_by_calling answers a call to an UNAVAILABLE tool with an error result" do
    tool_calls = messages(:weather_tool_call).content_tool_calls
    tool_calls[0][:function][:name] = "helloworld_nonexistent"
    tool_calls[0][:function][:arguments].delete(:name)

    msg = AIBackend::RubyLLM.get_tool_messages_by_calling(tool_calls).first
    assert_equal "tool", msg[:role], "The result should still be a tool message"
    assert_equal "abc123", msg[:tool_call_id], "The result should answer the call it was for"
    assert_equal tool_calls.first, msg[:content_tool_calls], "The original call should travel with the result"
    assert_includes JSON.parse(msg[:content])["error"], "unavailable tool `helloworld_nonexistent`", "RubyLLM should tell the model the tool doesn't exist"
  end

  test "get_tool_messages_by_calling returns one tool message per call IN CALL ORDER" do
    first = messages(:weather_tool_call).content_tool_calls.first
    second = first.deep_dup.merge(id: "def456")
    second[:function][:arguments] = { name: "Keith" }

    msgs = AIBackend::RubyLLM.get_tool_messages_by_calling([first, second])

    assert_equal ["abc123", "def456"], msgs.map { it[:tool_call_id] }, "Results should come back in the order the model asked"
    assert_equal ["\"Hello, World!\"", "\"Hello, Keith!\""], msgs.map { it[:content] }, "Each call should run with its own arguments"
  end

  test "get_tool_messages_by_calling KEEPS a Gemini thought signature on the call it returns" do
    tool_calls = messages(:weather_tool_call).content_tool_calls
    tool_calls[0][:thought_signature] = "sig-123"

    msg = AIBackend::RubyLLM.get_tool_messages_by_calling(tool_calls).first

    assert_equal "sig-123", msg[:content_tool_calls][:thought_signature], "Gemini rejects a replayed call without its signature"
  end
end
