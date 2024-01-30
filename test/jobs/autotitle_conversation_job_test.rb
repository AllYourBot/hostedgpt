require "test_helper"

class AutotitleConversationJobTest < ActiveJob::TestCase
  test "sets conversation title to 'Hear me'" do
    ChatCompletionAPI.stubs(:get_next_response).returns({"topic" => "Hear me"})

    conversation = conversations(:greeting)
    AutotitleConversationJob.perform_now(conversation.id)
    assert_equal "Hear me", conversation.reload.title
  end
end
