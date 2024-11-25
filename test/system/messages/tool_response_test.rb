require "application_system_test_case"

class ToolResponseTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @conversation = conversations(:memorize)
  end

  test "ensure a visible link is displayed to user that the memory was updated" do
    visit_and_scroll_wait conversation_messages_path(@conversation)
    assert_select "a", "Memory updated"
  end
end
