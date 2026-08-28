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

  test "code block shrinks with the viewport instead of forcing the page wider" do
    # A <pre> has white-space: pre, so its min-content width is the full unwrappable code line, and
    # overflow-x only zeroes the automatic minimum size of a *flex item*. So every flex item between
    # the <pre> and the body needs min-w-0, otherwise that min-content width becomes a floor and the
    # conversation stops shrinking (overflowing the page) once the viewport gets narrow enough. A long
    # line puts that floor up near the sidebar breakpoint, where it is most visible.
    long_line = "SELECT users.id, users.email, accounts.name FROM users INNER JOIN accounts " \
      "ON accounts.id = users.account_id WHERE users.deleted_at IS NULL ORDER BY users.created_at DESC LIMIT 100;"
    messages(:im_a_bot).update!(content_text: "Here you go:\n\n```sql\n#{long_line}\n```\n")
    visit_and_scroll_wait conversation_messages_path(@conversation)

    # Widths spanning the sidebar breakpoint (768px) down to very narrow.
    [900, 800, 768, 700, 500, 300].each do |width|
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
        width: width, height: 800, deviceScaleFactor: 1, mobile: false)

      assert_true "at #{width}px the conversation should not be wider than the viewport" do
        page.evaluate_script("document.querySelector(\"turbo-frame#conversation\").getBoundingClientRect().width") <= width
      end

      assert_true "at #{width}px the page should not scroll horizontally" do
        page.evaluate_script("document.documentElement.scrollWidth") <= width + 5
      end
    end
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end
end
