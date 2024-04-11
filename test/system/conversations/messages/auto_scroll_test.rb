require "application_system_test_case"

class ConversationMessagesAutoScrollTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @conversation = conversations(:attachment)
    @new_message = @conversation.messages.create! assistant: @conversation.assistant, content_text: "Stub: ", role: :assistant

    @time_start = Time.new.to_i
    visit conversation_messages_path(@conversation)
    wait_for_images_to_load
  end

  test "the conversation auto-scrolls to bottom when page loads" do
    assert_at_bottom
    assert_hidden "#scroll-button", "Page should have auto-scrolled to the bottom and hidden the scroll button."
  end

  test "the scroll appears and disappears based on scroll position" do
    assert_at_bottom

    assert_scrolled_up { scroll_to find_messages.second }
    assert_visible "#scroll-button"

    assert_scrolled_up { scroll_to first_message }
    assert_visible "#scroll-button"

    assert_scrolled_to_bottom { scroll_to last_message }
    assert_hidden "#scroll-button"
  end

  test "clicking scroll down button scrolls the page to the bottom" do
    assert_at_bottom
    assert_scrolled_up { scroll_to first_message }
    assert_visible "#scroll-button"

    assert_scrolled_to_bottom { click_element "#scroll-button button" }
    assert_hidden "#scroll-button"
  end

  test "submitting a message with ENTER inserts two new messages and scrolls down" do
    assert_stays_at_bottom "section #messages" do
      send_keys "Watch me appear"
      send_keys "enter"

      assert_true "The last user message should have contained the submitted text" do
        len = find_messages.length
        find_messages[len-2].text.include?("Watch me appear")
      end
    end
  end

  test "when the AI replies with a message it scrolls down" do
    assert last_message.text.include?("Stub:"), "The last message should have contained the submitted text"

    assert_stays_at_bottom "section #messages" do
      @new_message.content_text = "The quick brown fox jumped over the lazy dog and this line needs to wrap to scroll. " +
                                  "But it was not long enough so I'm adding more text on this second line to ensure it."
      GetNextAIMessageJob.broadcast_updated_message(@new_message)
      assert_true "The last message should have contained the submitted text" do
        last_message.text.include?("The quick brown")
      end
    end
  end
end
