require "test_helper"

class AutotitleConversationJobTest < ActiveJob::TestCase
  test "sets conversation title to 'Hear me'" do
    conversation = conversations(:greeting)

    ChatCompletionAPI.stub :get_next_response, {"topic" => "Hear me"} do
      AutotitleConversationJob.perform_now(conversation.id)
    end

    assert_equal "Hear me", conversation.reload.title
  end
end
