require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
  setup do
    login_as users(:keith)
  end

  test "the cursor is auto-focused in the text input for a new conversation and selecting existing conversation and ESC unfocuses" do
    assert_active "#composer textarea"
    send_keys "esc"
    assert_active "body"

    sleep 0.2

    click_on conversations(:greeting).title
    sleep 0.2
    assert_active "#composer textarea"
  end

  test "when cursor is not focused in the text input, / focuses it" do
    send_keys "esc"
    assert_active "body"

    send_keys "/"
    assert_active "#composer textarea"
  end
end
