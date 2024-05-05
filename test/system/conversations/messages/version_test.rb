require "application_system_test_case"

class ConversationMessagesVersionTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
  end

  test "previous icon shows tooltip and next is disabled" do
    conversations(:versioned).messages.where(version: 2).where("index > 2").destroy_all
    visit_and_scroll_wait conversation_messages_path(conversations(:versioned), version: 2)

    msg = hover_last_message
    assert_shows_tooltip msg.find_role("previous"), "Previous"
    assert msg.find_role("next").disabled?
  end

  test "next icon shows tooltip" do
    messages(:message3_v1).destroy
    visit_and_scroll_wait conversation_messages_path(conversations(:versioned), version: 1)

    msg = hover_last_message
    assert_shows_tooltip msg.find_role("next"), "Next"
    assert msg.find_role("previous").disabled?
  end

  test "changing conversation version morphs full page: messages change, nav does not scroll, active assistant changes" do
    messages(:message3_v1).destroy
    visit_and_scroll_wait conversation_messages_path(conversations(:versioned), version: 1)

    last_msg_v1 = messages(:message2_v1)

    assert_selected_assistant last_msg_v1.assistant
    assert_last_message last_msg_v1

    resize_browser_to(1400, 500)
    page.execute_script("document.querySelector('#nav-scrollable').scrollTop = 20") # scroll the nav column down slightly

    assert_at_bottom

    assert_did_not_scroll "#nav-scrollable" do
      msg = hover_last_message
      next_version = msg.find_role("next")
      next_version.click
    end

    assert_at_bottom

    last_msg_v2 = messages(:message5_v2)

    assert_selected_assistant last_msg_v2.assistant
    assert_last_message last_msg_v2
  end
end
