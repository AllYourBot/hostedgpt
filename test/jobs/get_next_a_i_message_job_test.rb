require "test_helper"

class GetNextAIMessageJobTest < ActiveJob::TestCase
  test "adds a new message from the assistant" do
    @conversation = conversations(:greeting)
    @conversation.messages.create! role: :assistant, content_text: "", assistant: @conversation.assistant
    @test_client = TestClients::OpenAI.new(access_token: 'abc')

    assert_no_difference "@conversation.messages.reload.length" do
      GetNextAIMessageJob.perform_now(@conversation.id, assistants(:samantha).id)
    end

    message_text = @test_client.chat.dig("choices", 0, "message", "content")
    assert_equal message_text, @conversation.messages.ordered.last.content_text
  end
end
