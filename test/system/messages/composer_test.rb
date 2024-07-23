require "application_system_test_case"

class MessagesComposerTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @long_conversation = conversations(:greeting)
  end

  test "the cursor is auto-focused in the text input for a new conversation and selecting existing conversation and ESC unfocuses" do
    sleep 0.2
    assert_active composer_selector
    send_keys "esc"
    assert_active "body"

    sleep 0.2

    click_text @long_conversation.title
    wait_for_images_to_load
    assert_active composer_selector
  end

  test "when cursor is not focused in the text input, / focuses it and then an accidental second / does not appear" do
    send_keys "esc"
    assert_active "body"

    send_keys "/"
    assert_active composer
    assert_equal "", composer.value

    send_keys "/"
    assert_equal "", composer.value
  end

  test "when cursor is focused in the text input, ? works as a key press" do
    assert_equal "", composer.value
    send_keys "?"
    assert_equal "?", composer.value
  end

  test "when not in text input, ? opens the keyboard shortcuts and ESC dismisses it and keyboard shortcuts work normally" do
    send_keys "esc"
    assert_active "body"
    refute_text "Keyboard shortcuts"

    send_keys "?"
    assert_text "Keyboard shortcuts"

    send_keys "esc"
    refute_text "Keyboard shortcuts"

    send_keys "/"
    assert_active composer
  end

  test "when not in text input, ? opens the keyboard shortcuts and CLICKING OUTSIDE dismisses it and keyboard shortcuts work normally" do
    send_keys "esc"
    assert_active "body"
    refute_text "Keyboard shortcuts"

    send_keys "?"
    assert_text "Keyboard shortcuts"

    page.execute_script("document.querySelector('#modal-backdrop').click()") # passes a click event directly to the element
    refute_text "Keyboard shortcuts"

    send_keys "/"
    assert_active composer
  end

  # TODO: what about auto focus for existing conversation? That's causing a submitting_test to fail


  # TODO: We do not have a test for the smart paste. I'm not sure how to programmatically paste from within capybara
end
