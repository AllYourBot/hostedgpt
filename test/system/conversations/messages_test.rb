require "application_system_test_case"

class ConversationMessagesTest < ApplicationSystemTestCase
  setup do
    login_as users(:keith)
    @long_conversation = conversations(:greeting)
  end

  test "the conversation auto-scrolls to bottom when page loads" do
    click_on @long_conversation.title

    assert_hidden "#scroll-button", "Page should have auto-scrolled to the bottom and hidden the scroll button."
  end

  test "the scroll appears and disappears based on scroll position" do
    click_on @long_conversation.title

    first_message = all("#conversation .message")[0]
    second_message = all("#conversation .message")[1]
    last_message = all("#conversation .message").last

    scroll_to second_message
    assert_visible "#scroll-button", wait: 0.2

    scroll_to first_message
    assert_visible "#scroll-button", wait: 0.2

    scroll_to last_message
    assert_hidden "#scroll-button", wait: 0.2
  end

  test "clicking scroll down button scrolls the page to the bottom" do
    click_on @long_conversation.title

    scroll_to all("#conversation .message").first
    assert_visible "#scroll-button", wait: 0.2

    find("#scroll-button a").click
    assert_hidden "#scroll-button", wait: 0.2
  end

  # This behavior is actually broken right now but I think Rob's PR will fix
  #
  # test "when a message arrives while viewing the conversation, it is displayed and scrolled into view" do
  #   click_on @long_conversation.title

  #   @long_conversation.messages.create! assistant: @long_conversation.assistant, content_text: "I'm a new message, watch me appear!", role: :user
  #   assert_text "I'm a new message, watch me appear!", wait: 2
  #   assert_hidden "#scroll-button"
  # end
end
