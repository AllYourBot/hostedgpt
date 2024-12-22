require "test_helper"

class Message::ToolableTest < ActiveSupport::TestCase
  setup do
    @has_tool_response = { role: :tool, tool_call_id: "abc123", content_text: "success", content_tool_calls: { function: "hello" } }
    @has_tool_calls = { content_tool_calls: { func: "hello" } }
    @has_content_text = { content_text: "Hello" }
  end

  test "only_tool_response? is true if this message has tool details and no user-facing content" do
    assert Message.new( @has_tool_response ).only_tool_response?
    assert Message.new( @has_tool_calls ).only_tool_response?

    refute Message.new( @has_tool_calls.merge(@has_content_text) ).only_tool_response?
  end

  test "tool_related? is true if this message has tool details regardless of whether it has user-facing content" do
    assert Message.new( @has_tool_response ).tool_related?
    assert Message.new( @has_tool_calls ).tool_related?

    assert Message.new( @has_tool_calls.merge(@has_content_text) ).tool_related?
  end
end
