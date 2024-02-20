require "application_system_test_case"

class MessagesComposerTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @submit = find("#composer #send") # oddly, when I changed id="submit" on the button the form fails to submit
    @input_selector = "#composer textarea"
  end

  test "the cursor is auto-focused in the text input for a new conversation and selecting existing conversation and ESC unfocuses" do
    assert_active @input_selector
    send_keys "esc"
    assert_active "body"

    sleep 0.2

    click_text conversations(:greeting).title
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
    click_element @submit
    assert_equal path, current_path, "Path should not have changed because form should not submit"

    click_element input # focus is lost after the attempted click on submit so we need to refocus
    send_keys "Entered text so we can now submit"
    refute @submit.disabled?
    click_element @submit
    sleep 0.3

    assert_equal conversation_messages_path(@user.conversations.ordered.first), current_path, "Should have redirected to newly created conversation"
    assert input.value.blank?
  end

  test "enter works to submit but only when text has been entered" do
    path = current_path

    assert @submit.disabled?
    send_keys "enter"
    assert_equal path, current_path, "Path should not have changed because form should not submit"

    send_keys "Entered text so we can now submit"
    refute @submit.disabled?
    send_keys "enter"
    sleep 0.3

    assert_equal conversation_messages_path(@user.conversations.ordered.first), current_path, "Should have redirected to newly created conversation"
    assert input.value.blank?
  end

  test "shift+enter inserts a newline and then enter submits" do
    path = current_path

    send_keys "First line"
    send_keys "shift+enter"
    send_keys "Second line"
    assert_equal "First line\nSecond line", input.value
    assert_equal path, current_path, "Path should not have changed because form should not submit"

    send_keys "enter"
    sleep 0.3

    assert_equal conversation_messages_path(@user.conversations.ordered.first), current_path, "Should have redirected to newly created conversation"
    assert input.value.blank?
  end

  test "textarea grows in height as newlines are added and shrinks in height when they are removed" do
    click_text conversations(:greeting).title
    sleep 1

    send_keys "1"
    height = input.native.property('clientHeight')
    scroll = get_scroll_position("#right-content")

    send_keys "shift+enter"
    sleep 0.3
    assert input.native.property('clientHeight') > height, "Input should have grown taller"
    assert get_scroll_position("#right-content") > scroll, "The page should have scrolled back down"
    height = input.native.property('clientHeight')
    scroll = get_scroll_position("#right-content")

    send_keys "2"
    send_keys "shift+enter"
    sleep 0.3
    assert input.native.property('clientHeight') > height, "Input should have grown taller"
    assert get_scroll_position("#right-content") > scroll, "The page should have scrolled back down"
    height = input.native.property('clientHeight')
    scroll = get_scroll_position("#right-content")

    send_keys "backspace"
    sleep 0.3
    assert input.native.property('clientHeight') < height, "Input should have gotten shorter"
    assert get_scroll_position("#right-content") < scroll, "The page should have scrolled back up"
    height = input.native.property('clientHeight')
    scroll = get_scroll_position("#right-content")

    send_keys "backspace+backspace"
    sleep 0.3
    assert input.native.property('clientHeight') < height, "Input should have gotten shorter"
    assert get_scroll_position("#right-content") < scroll, "The page should have scrolled back up"
    height = input.native.property('clientHeight')
    scroll = get_scroll_position("#right-content")

    send_keys "backspace+backspace"
    sleep 0.3
    assert input.native.property('clientHeight') == height, "Input should not have changed height"
    assert get_scroll_position("#right-content") == scroll, "The page should not have scrolled"
  end

  test "textarea grows in height and auto-scrolls messages when a large block of text is pasted" do
    click_text conversations(:greeting).title
    sleep 1
    height = input.native.property('clientHeight')
    scroll = get_scroll_position("#right-content")

    text = <<~END
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
      The quick brown fox jumped over the lazy dog.
    END
    send_keys text.gsub(/\n/, ' ')
    sleep 0.3
    assert input.native.property('clientHeight') > height, "Input should have grown taller"
    assert get_scroll_position("#right-content") > scroll, "The page should have scrolled back down"
    height = input.native.property('clientHeight')
    scroll = get_scroll_position("#right-content")
  end

  test "submitting a couple messages to an existing conversation with ENTER works" do
    click_text conversations(:greeting).title
    sleep 0.3
    path = current_path

    send_keys "This is a message"
    send_keys "enter"
    sleep 0.3

    assert_equal path, current_path, "The page should not have changed urls"
    assert input.value.blank?, "The composer should have cleared itself"

    send_keys "This is a second message"
    send_keys "enter"
    sleep 0.3

    assert_equal path, current_path, "The page should not have changed urls"
    assert input.value.blank?, "The composer should have cleared itself"
  end

  test "submitting a couple messages to an existing conversation with CLICKING works" do
    click_text conversations(:greeting).title
    sleep 0.3
    path = current_path

    send_keys "This is a message"
    click_element @submit
    sleep 0.3

    assert_equal path, current_path, "The page should not have changed urls"
    assert input.value.blank?, "The composer should have cleared itself"

    send_keys "This is a second message"
    click_element @submit
    sleep 0.3

    assert_equal path, current_path, "The page should not have changed urls"
    assert input.value.blank?, "The composer should have cleared itself"
  end

  private

  def input
    find(@input_selector)
  end
end
