require "test_helper"

class MessagesHelperTest < ActionView::TestCase

  test "memory_updated responds properly for tool result" do
    message = messages(:keep_memory_tool_result)
    assert memory_updated?(message)
  end

  test "message_to_user_from_tool_call responds properly for tool result" do
    message = messages(:keep_memory_tool_result)
    assert message_to_user_from_tool_call?(message)
  end

  test "from_name_for responds properly for tool result" do
    message = messages(:keep_memory_tool_result)
    assert_nil from_name_for(message)
  end
end
