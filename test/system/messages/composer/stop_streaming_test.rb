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

    assert_selector "#composer #cancel"

    reply = @conversation.messages.ordered.last
    reply.update!(content_text: "Foo bar")
    stream_ai_message(reply)
    finish_streaming

    assert_no_selector "#composer #cancel"
  end

  test "stop button shows in composer while replying and clicking cancel stops it" do
    send_keys "You there?"
    send_keys "enter"

    assert_selector "#composer #cancel"

    reply = @conversation.messages.ordered.last
    reply.update!(content_text: "Foo bar")
    stream_ai_message(reply)

    refute reply.reload.cancelled?
    click_element "#composer #cancel"
    assert_true { reply.reload.cancelled? }

    assert_no_selector "#composer #cancel"
  end

  private

  def stream_ai_message(msg)
    GetNextAIMessageJob.broadcast_updated_message(msg)
    sleep 1 # without this I get a stale element reference on this next line which I cannot understand...
    assert_true(wait: 10) do
      last_message.text.include?(msg.content_text)
    end
  end

  def finish_streaming
    @conversation.broadcast_refresh
  end
end