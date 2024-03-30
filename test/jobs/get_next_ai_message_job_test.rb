require "test_helper"

class GetNextAIMessageJobOpenaiTest < ActiveJob::TestCase
  setup do
    @conversation = conversations(:greeting)
    @message = @conversation.messages.create! role: :assistant, content_text: "", assistant: @conversation.assistant
    @test_client = TestClients::OpenAI.new(access_token: 'abc')
  end

  test "if a new message is created before job starts, it does not process" do
    @conversation.messages.create! role: :user, content_text: "You there?", assistant: @conversation.assistant
    refute GetNextAIMessageJob.perform_now(@message.id, @conversation.assistant.id)
  end

  test "if the cancel streaming button is clicked before job starts, it does not process" do
    @message.cancelled!
    refute GetNextAIMessageJob.perform_now(@message.id, @conversation.assistant.id)
  end

  # TODO: Does redis run during tests?
end
