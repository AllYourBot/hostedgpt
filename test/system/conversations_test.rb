require "application_system_test_case"

class ConversationsTest < ApplicationSystemTestCase
  setup do
    @conversation = conversations(:greeting)
    @assistant = assistants(:keith_gpt4)
    login_as @conversation.user
  end

  test "visiting the index" do
    visit conversations_url
    assert_selector "h1", text: "Conversations"
  end

  test "creating new chat with meta+shift+o" do
    visit conversation_messages_path(@conversation)

    page.driver.browser.action.key_down(:meta)
                              .key_down(:shift)
                              .send_keys("o")
                              .key_up(:meta)
                              .key_up(:shift)
                              .perform

    expected_path = new_assistant_message_path(@assistant)

    assert_current_path(expected_path)
  end

  test "creating new chat with meta+j" do
    visit conversation_messages_path(@conversation)

    page.driver.browser.action.key_down(:meta)
                              .send_keys("j")
                              .key_up(:meta)
                              .perform

    expected_path = new_assistant_message_path(@assistant)

    assert_current_path(expected_path)
  end
end
