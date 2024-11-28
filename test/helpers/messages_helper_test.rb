require "test_helper"

class MessagesHelperTest < ActionView::TestCase

  test "recognizes memory updated" do
    message = messages(:keep_memory_tool_result)
    assert memory_updated?(message)
  end

  test "recognizes message to user from tool call" do
    message = messages(:keep_memory_tool_result)
    assert message_to_user_from_tool_call?(message)
  end

  test "recognizes message to user from tool call" do
    message = messages(:keep_memory_tool_result)
    assert_nil from_name_for(message)
  end
end