require "application_system_test_case"

class ConversationMessagesHtmlTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @conversation = conversations(:greeting)
    visit conversation_messages_path(@conversation)
  end

  test "html is escaped so that it renders to the user" do
    orig_msg_text = @conversation.messages.ordered.first.content_text
    displayed_msg_text = first_message.find_role("content-text").text
    assert_equal orig_msg_text, displayed_msg_text, "The HTML tag was not escaped"
  end

  test "newlines within a paragraph are preserved" do
    orig_msg_text = @conversation.messages.ordered.third.content_text
    displayed_msg_text = find_messages.third.find_role("content-text").text
    assert_equal orig_msg_text.gsub("\n\n", "\n").strip, displayed_msg_text, "Newlines within a paragraph are not preserved"
  end
end
