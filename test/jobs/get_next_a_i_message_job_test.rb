require "test_helper"

class GetNextAIMessageJobTest < ActiveJob::TestCase
  test "adds a new message from the assistant" do
    @conversation = conversations(:greeting)
    @test_client = TestClients::OpenAI.new(access_token: 'abc')

    assert_difference "@conversation.messages.reload.length", 1 do
      GetNextAIMessageJob.perform_now(@conversation.id, assistants(:samantha).id)
    end

    message_text = @test_client.chat.dig("choices", 0, "message", "content")
    assert_equal message_text, @conversation.messages.ordered.last.content_text
  end
end
