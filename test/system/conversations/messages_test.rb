require "application_system_test_case"

class ConversationMessagesTest < ApplicationSystemTestCase
  setup do
    login_as users(:keith)
  end

  test "the cursor" do
    @long_conversation = conversations(:greeting)

    click_on @long_conversation.title

    first_message = all("#conversation .message")[0]
    second_message = all("#conversation .message")[1]
    last_message = all("#conversation .message").last

    assert_hidden "#scroll-button", "Page should have auto-scrolled to the bottom and hidden the scroll button."

    scroll_to second_message
    sleep 0.1
    assert_visible "#scroll-button"

    scroll_to first_message
    sleep 0.1
    assert_visible "#scroll-button"

    scroll_to last_message
    sleep 0.1
    assert_hidden "#scroll-button"
  end

end
