require "application_system_test_case"

class MessagesComposerResettingTest < ApplicationSystemTestCase
  include MorphingHelper

  setup do
    login_as users(:keith)
    @conversation = conversations(:greeting)
    visit_and_scroll_wait conversation_messages_path(@conversation)
  end

  test "the composer clears after the user presses submit, but if they start typing really quickly it won't clear with the final morph" do
    assert_page_morphed do
      assert_scrolled_down do
        send_keys "Text has been entered"
        send_keys "enter"
      end
    end

    assistant_reply = Message.last
    assistant_reply.content_text = "Assistant reply"
    GetNextAIMessageJob.broadcast_updated_message(assistant_reply)

    assert_composer_blank
    send_keys "New text"
    assert_equal "New text", composer.value

    assert_page_morphed do
      assert_scrolled_down do
        assistant_reply.content_text = "Assistant reply has gotten really long so that I can ensure it wraps and the page " +
          "will need to scroll down in order to accomodate the wrapped lines. The quick brown fox jumped over the lazy dog. " +
          "The quick brown fox jumped over the lazy dog."
        assistant_reply.save!
        @conversation.broadcast_refresh_to @conversation
      end
    end

    assert_equal "New text", composer.value, "Composer should not have cleared what the user typed"
  end
end
