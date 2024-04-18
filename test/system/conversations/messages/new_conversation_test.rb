require "application_system_test_case"

class ConversationMessagesNewConversationTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @conversation = conversations(:greeting)
    visit conversation_messages_path(@conversation)
  end

  test "clicking new compose icon in the top-right starts a new conversation and preserves sidebar scroll" do
    header = find("#conversation #wide-header")

    new_chat = header.find_role("new")
    assert_shows_tooltip new_chat, "New chat"

    assert conversation_selected_in_nav(@conversation)
    new_chat.click
    assert_current_path new_assistant_message_path(@conversation.assistant)
    refute conversation_selected_in_nav(@conversation)
  end

  test "creating new chat with meta+shift+o" do
    send_keys("meta+shift+o")

    expected_path = new_assistant_message_path(@conversation.assistant)

    assert_current_path(expected_path)
  end

  test "creating new chat with meta+j" do
    send_keys("meta+j")

    expected_path = new_assistant_message_path(@conversation.assistant)

    assert_current_path(expected_path)
  end

  private

  def conversation_selected_in_nav(conversation)
    find("#conversation-#{conversation.id}").find(:xpath, '..').matches_css?(".relationship", wait: 0)
  end
end
