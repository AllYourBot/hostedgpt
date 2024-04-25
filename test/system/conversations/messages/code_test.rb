require "application_system_test_case"

class ConversationMessagesCodeTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @conversation = conversations(:greeting)
    visit_and_scroll_wait conversation_messages_path(@conversation)
    @code_msg = last_message
  end

  test "code block renders with a proper header" do
    assert_includes @code_msg.text, "sql", "SQL should be in the header"
    assert_includes @code_msg.text, "Copy code", "Copy code should be in the header"
    refute_includes @code_msg.text, "Copied", "Copied should be in the header"
  end

  test "clicking copy on code block changes icon and copies to clipboard" do
    assert_true { clipboard == "" }

    @code_msg.find_role("code-clipboard").click
    assert_equal "SELECT * FROM users", clipboard

    assert_includes @code_msg.text, "Copied", "Copied should be in the header"
    refute_includes @code_msg.text, "Copy code", "Copy code should be in the header"
  end

  test "clicking copy on the overall message that includes code copies everything to clipboard and adds in the backticks" do
    assert_true { clipboard == "" }

    @code_msg.hover
    copy = @code_msg.find_role("clipboard")
    copy.click

    assert_equal messages(:im_a_bot).content_text.strip, clipboard
    assert_shows_tooltip copy, "Copied!"
  end

  test "using the overall keyboard shortcut for copying copies the code block within the last message" do
    assert_true { clipboard == "" }
    send_keys "meta+shift+c"
    assert_equal "SELECT * FROM users", clipboard
  end

  test "using the overall keyboard shortcut for copying copies the full last message where there is NO code block" do
    conversation = conversations(:javascript)
    visit_and_scroll_wait conversation_messages_path(conversation)

    assert_true { clipboard == "" }
    send_keys "meta+shift+c"
    assert_true { conversation.messages.ordered.last.content_text.strip == clipboard }
  end
end
