require "application_system_test_case"

class ConversationMessagesStopStreamingTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @conversation = conversations(:greeting)
  end

  test "an empty cancelled message shows the stopped icon without ..." do
    messages(:dont_know_day).update!(content_text: nil, cancelled_at: Time.current)
    visit conversation_messages_path(@conversation)

    msg = find("#message_#{messages(:dont_know_day).id}")

    assert_equal "", msg.find_role("content-text").text
    assert msg.find_role("cancelled").visible?
  end

  test "a cancelled message with some text shows the stopped icon with ..." do
    messages(:dont_know_day).update!(content_text: "But I", cancelled_at: Time.current)
    visit conversation_messages_path(@conversation)

    msg = find("#message_#{messages(:dont_know_day).id}")

    assert msg.find_role("content-text").text.include?("...")
    assert msg.find_role("cancelled").visible?
  end
end
