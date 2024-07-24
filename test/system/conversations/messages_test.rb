require "application_system_test_case"

class ConversationMessagesTest < ApplicationSystemTestCase
  include MorphingHelper

  setup do
    15.times { |i| users(:keith).conversations.create!(assistant: assistants(:samantha), title: "Conversation #{i+1}") }

    @user = users(:keith)
    login_as @user
    @conversation = conversations(:greeting)
    visit_and_scroll_wait conversation_messages_path(@conversation)
  end

  test "clipboard icon shows tooltip" do
    msg = hover_last_message
    assert_shows_tooltip msg.find_role("clipboard"), "Copy"
  end

  test "clicking clipboard icon changes the tooltip & icon to check, mousing out changes it back" do
    msg = hover_last_message
    clipboard = msg.find_role("clipboard")

    clipboard.click
    assert_shows_tooltip clipboard, "Copied!"

    msg.find_role("regenerate").hover
    assert_shows_tooltip clipboard, "Copy"
  end

  test "regenerate icon shows tooltip" do
    msg = hover_last_message
    assert_shows_tooltip msg.find_role("regenerate"), "Regenerate"
  end

  test "clicking regenerate icon shows menu and triggers re-generation" do
    existing_assistant = @conversation.assistant
    new_assistant = @user.assistants.ordered.where.not(id: existing_assistant.id).first

    msg = hover_last_message
    regenerate = msg.find_role("regenerate")

    regenerate.click
    assert_text "Using #{existing_assistant.name}"
    assert_text "Using #{new_assistant.name}"

    assert_equal existing_assistant.name, last_message.find_role("from").text

    click_text "Using #{new_assistant.name}"

    assert_true do
      last_message.find_role("from").text == new_assistant.name
    end
    assert_current_path conversation_messages_path(@conversation, version: 2)
  end

  test "submitting a message with ENTER inserts two new messages with morphing" do
    assert_page_morphed do
      assert_scrolled_down do
        send_keys "Watch me appear"
        send_keys "enter"

        assert_true "The last user message should contain the submitted text" do
          len = find_messages.length
          find_messages[len-2].text.include?("Watch me appear")
        end
      end
    end
  end

  test "when the AI replies with a message it appears with morphing" do
    @new_message = @conversation.messages.create! assistant: @conversation.assistant, content_text: "Stub: ", role: :assistant
    visit_and_scroll_wait conversation_messages_path(@conversation.id)

    assert last_message.text.include?("Stub:"), "The last message should have contained the submitted text"

    assert_page_morphed do
      assert_scrolled_down do
        @new_message.content_text = "The quick brown fox jumped over the lazy dog and this line needs to wrap to scroll. " +
                                    "But it was not long enough so I'm adding more text on this second line to ensure it."
        GetNextAIMessageJob.broadcast_updated_message(@new_message)
        sleep 5 # TODO: cannot solve a "stale element reference" bug so trying this
        assert_true "The last message should have contained the submitted text but it contains '#{last_message.text}'", wait: 10 do
          last_message.text.include?("The quick brown")
        end
        @new_message.save!
      end
    end
  end
end
