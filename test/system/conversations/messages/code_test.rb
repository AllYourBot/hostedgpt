require "application_system_test_case"

class ConversationMessagesCodeTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @long_conversation = conversations(:greeting)

    click_text @long_conversation.title
    sleep 0.2
    @code_msg = last_message
  end

  test "code block renders with a proper header" do
    assert_includes @code_msg.text, "sql", "SQL should be in the header"
    assert_includes @code_msg.text, "Copy code", "Copy code should be in the header"
    refute_includes @code_msg.text, "Copied", "Copied should be in the header"
  end

  test "clicking copy on code block changes icon and copies to clipboard" do
    assert_nil clipboard
    node("code-clipboard", within: @code_msg).click
    assert_equal "SELECT * FROM users\n", clipboard
    assert_includes @code_msg.text, "Copied", "Copied should be in the header"
    refute_includes @code_msg.text, "Copy code", "Copy code should be in the header"
  end

  test "using the overall keyboard shortcut for copying copies the code block within the last message" do
    assert_nil clipboard
    send_keys "meta+shift+c"
    assert_equal "SELECT * FROM users\n", clipboard
  end

  test "using the overall keyboard shortcut for copying copies the full last message where there is NO code block" do
    conversation = conversations(:javascript)
    click_text conversation.title
    sleep 0.2

    assert_nil clipboard
    send_keys "meta+shift+c"
    assert_equal conversation.messages.ordered.last.content_text, clipboard
  end
end
