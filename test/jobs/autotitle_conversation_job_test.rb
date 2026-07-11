require "test_helper"

class AutotitleConversationJobTest < ActiveJob::TestCase
  test "sets conversation title automatically when there are two messages" do
    TestChat.reset
    conversation = conversations(:greeting)

    TestChat.text = "{\"topic\":\"Hear me\"}"
    AutotitleConversationJob.perform_now(conversation.id)

    assert_equal "Hear me", conversation.reload.title
  end

  test "sets conversation title automatically even if there is only one message" do
    TestChat.reset
    conversation = conversations(:javascript)
    conversation.latest_message_for_version(:latest).destroy!

    TestChat.text = "{\"topic\":\"Javascript popState\"}"
    AutotitleConversationJob.perform_now(conversation.id)

    assert_equal "Javascript popState", conversation.reload.title
  end

  test "the topic is not set if the conversation has no messages" do
    TestChat.reset
    conversation = users(:keith).conversations.create!(assistant: assistants(:samantha))
    conversation.update!(updated_at: Time.current) # update is what triggers the callback

    assert_nothing_raised do
      TestChat.text = "{\"topic\":\"Javascript popState\"}"
      AutotitleConversationJob.perform_now(conversation.id)
    end

    assert_nil conversation.reload.title
  end

  test "extracts the topic from a non-JSON response using the fallback regex" do
    TestChat.reset
    conversation = conversations(:greeting)

    TestChat.text = 'The topic is:"Hear me now"'
    AutotitleConversationJob.perform_now(conversation.id)

    assert_equal "Hear me now", conversation.reload.title
  end
end
