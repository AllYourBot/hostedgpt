require "application_system_test_case"

class ConversationsTest < ApplicationSystemTestCase
  setup do
    login_as users(:keith)
  end

  test "visiting the index" do
    visit conversations_url
    assert_selector "h1", text: "Conversations"
  end

  test "creating new chat with meta+shift+o" do
    visit conversation_messages_path(conversations(:greeting))
    send_keys("meta+shift+o")

    expected_path = new_assistant_message_path(conversations(:greeting).assistant)

    assert_current_path(expected_path)
  end

  test "creating new chat with meta+j" do
    visit conversation_messages_path(conversations(:javascript))
    send_keys("meta+j")

    expected_path = new_assistant_message_path(conversations(:javascript).assistant)

    assert_current_path(expected_path)
  end


end
