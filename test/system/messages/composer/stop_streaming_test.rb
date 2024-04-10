require "application_system_test_case"

class MessagesComposerStopStreamingTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @conversation = conversations(:greeting)
    visit conversation_messages_path(@conversation)
  end

  test "stop button shows in composer while replying and disappears when done" do
    send_keys "You there?"
    send_keys "enter"
    sleep 0.2

    assert_selector "#composer #cancel"

    reply = @conversation.messages.ordered.last
    reply.update!(content_text: "Yes")
    stream_ai_message(reply)
    finish_streaming

    assert_no_selector "#composer #cancel"
  end

  test "stop button shows in composer while replying and clicking cancel stops it" do
    send_keys "You there?"
    send_keys "enter"
    sleep 0.2

    assert_selector "#composer #cancel"

    reply = @conversation.messages.ordered.last
    reply.update!(content_text: "Yes")
    stream_ai_message(reply)
    sleep 0.2

    assert_changes "reply.reload.cancelled?", from: false, to: true do
      click_element "#composer #cancel"
      sleep 0.3
    end

    assert_no_selector "#composer #cancel"
  end

  private

  def stream_ai_message(msg)
    GetNextAIMessageJob.broadcast_updated_message(msg)
  end

  def finish_streaming
    @conversation.broadcast_refresh
    sleep 0.2
  end
end