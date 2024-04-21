require "test_helper"

class AutotitleConversationJobTest < ActiveJob::TestCase
  test "sets conversation title automatically when there are two messages" do
    conversation = conversations(:greeting)

    ChatCompletionAPI.stub :get_next_response, {"topic" => "Hear me"} do
      AutotitleConversationJob.perform_now(conversation.id)
    end

    assert_equal "Hear me", conversation.reload.title
  end

  test "sets conversation title automatically even if there is only one message" do
    conversation = conversations(:javascript)
    conversation.latest_message_for_version(:latest).destroy!

    ChatCompletionAPI.stub :get_next_response, {"topic" => "Javascript popState"} do
      AutotitleConversationJob.perform_now(conversation.id)
    end

    assert_equal "Javascript popState", conversation.reload.title
  end

  test "the topic is not set if the conversation has no messages" do
    conversation = users(:keith).conversations.create!(assistant: assistants(:samantha))
    conversation.update!(updated_at: Time.current) # update is what triggers the callback

    assert_nothing_raised do # confirms the exception did not raise outside the job
      ChatCompletionAPI.stub :get_next_response, {"topic" => "This will not be set"} do
        AutotitleConversationJob.perform_now(conversation.id)
      end
    end

    assert_nil conversation.reload.title # and confirm the job didn't do anything
  end
end
