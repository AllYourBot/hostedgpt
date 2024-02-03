require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
  end

  test "after logging in, the user is redirected to the right path" do
    assistant = @user.assistants.order(:id).first
    assert_current_path new_assistant_message_path(assistant)
  end

  test "visiting the index defaults to GPT-4 and starts a new conversation" do
    assistant = @user.assistants.order(:id).first

    visit root_url

    assert_current_path new_assistant_message_path(assistant)
    assert_selector "#assistants .relationship", text: "GPT-4"
  end
end
