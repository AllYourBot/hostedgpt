require "test_helper"

class GetNextAIMessageJobTest < ActiveJob::TestCase
  setup do
    @conversation = conversations(:greeting)
    @message = @conversation.messages.create! role: :assistant, content_text: "", assistant: @conversation.assistant
    @test_client = TestClients::OpenAI.new(access_token: 'abc')
  end

  test "adds a new message from the assistant" do
    assert_no_difference "@conversation.messages.reload.length" do
      assert GetNextAIMessageJob.perform_now(@message.id, assistants(:samantha).id)
    end

    message_text = @test_client.chat.dig("choices", 0, "message", "content")
    assert_equal message_text, @conversation.latest_message.content_text
  end

  test "returns early if the message id was invalid" do
    refute GetNextAIMessageJob.perform_now(0, assistants(:samantha).id)
  end

  test "returns early if the assistant id was invalid" do
    refute GetNextAIMessageJob.perform_now(@message.id, 0)
  end

  test "returns early if the message was already generated" do
    @message.update!(content_text: "Hello")
    refute GetNextAIMessageJob.perform_now(@message.id, assistants(:samantha).id)
  end

  test "returns early if the user has replied after this" do
    @conversation.messages.create! role: :user, content_text: "Ignore that, new question:", assistant: @conversation.assistant
    refute GetNextAIMessageJob.perform_now(@message.id, assistants(:samantha).id)
  end
end
