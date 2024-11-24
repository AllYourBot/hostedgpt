require "application_system_test_case"

class ToolResponseTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @conversation = conversations(:weather)
  end

  test "ensure a message is displayed to user that the weather was fetched" do
    visit_and_scroll_wait conversation_messages_path(@conversation)
    # binding.pry
    # TODO: Add weather_tool_call: to fixtures
    # assert_text "Good summary: sunny"
  end

  # TODO: test "ensure a visible link is displayed to user that the memory was updated" do
end
