require "application_system_test_case"

class MessagesComposerTest < ApplicationSystemTestCase
  setup do
    login_as users(:keith)
    @submit = find("#composer #send") # oddly, when I changed id="submit" on the button the form fails to submit
    @input_selector = "#composer textarea"
    @input = find(@input_selector)
  end

  test "the cursor is auto-focused in the text input for a new conversation and selecting existing conversation and ESC unfocuses" do
    assert_active @input_selector
    send_keys "esc"
    assert_active "body"

    sleep 0.2

    click_on conversations(:greeting).title
    sleep 0.2
    assert_active @input_selector
  end

  test "when cursor is not focused in the text input, / focuses it" do
    send_keys "esc"
    assert_active "body"

    send_keys "/"
    assert_active @input_selector
  end

  test "submit button is disabled and cannot be clicked until text is entered" do
    path = current_path

    assert @submit.disabled?
    @submit.click
    assert_equal path, current_path, "Path should not have changed because form should not submit"

    @input.click # focus is lost after the attempted click on submit
    send_keys "Entered text so we can now submit"
    refute @submit.disabled?
    @submit.click
    assert_not_equal path, current_path
  end

  test "enter works to submit but only when text has been entered" do
    path = current_path

    assert @submit.disabled?
    send_keys "enter"
    assert_equal path, current_path, "Path should not have changed because form should not submit"

    send_keys "Entered text so we can now submit"
    refute @submit.disabled?
    send_keys "enter"
    assert_not_equal path, current_path, "Path should have changed because form should have submitted"
  end

  test "shift+enter inserts a newline and then enter submits" do
    path = current_path

    send_keys "First line"
    send_keys "shift+enter"
    send_keys "Second line"
    assert_equal "First line\nSecond line", @input.value
    assert_equal path, current_path, "Path should not have changed because form should not submit"

    send_keys "enter"
    assert_not_equal path, current_path, "Path should have changed because form should have submitted"
  end
end
