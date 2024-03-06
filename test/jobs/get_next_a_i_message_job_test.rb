require "test_helper"

class GetNextAIMessageJobTest < ActiveJob::TestCase
  setup do
    @conversation = conversations(:greeting)
    @message = @conversation.messages.create! role: :assistant, content_text: "", assistant: @conversation.assistant
    @test_client = TestClients::OpenAI.new(access_token: 'abc')
  end

  test "populates the latest message from the assistant" do
    assert_no_difference "@conversation.messages.reload.length" do
      assert GetNextAIMessageJob.perform_now(@message.id, assistants(:samantha).id)
    end

    message_text = @test_client.chat.dig("choices", 0, "message", "content")
    assert_equal message_text, @conversation.latest_message.content_text
  end

  test "re-populates an earlier message from the assistant if it was provided and marked as re-requested" do
    messages(:yes_i_do).update!(rerequested_at: Time.current, content_text: nil)

    assert_no_difference "@conversation.messages.reload.length" do
      assert GetNextAIMessageJob.perform_now(messages(:yes_i_do).id, assistants(:samantha).id)
    end

    message_text = @test_client.chat.dig("choices", 0, "message", "content")
    assert_equal message_text, messages(:yes_i_do).reload.content_text
    assert_not_equal message_text, @conversation.latest_message.content_text
  end

  test "returns early if attempting to re-populate an earlier message from the assistant if it was provided but NOT marked as re-requested" do
    messages(:yes_i_do).update!(content_text: nil)

    assert_no_difference "@conversation.messages.reload.length" do
      refute GetNextAIMessageJob.perform_now(messages(:yes_i_do).id, assistants(:samantha).id)
    end

    message_text = @test_client.chat.dig("choices", 0, "message", "content")
    assert_not_equal message_text, messages(:yes_i_do).reload.content_text
    assert_not_equal message_text, @conversation.latest_message.content_text
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

  # TODO: Be sure to test for cancelled_at case when we finish implementing cancelled

  test "returns early if the user has replied after this" do
    @conversation.messages.create! role: :user, content_text: "Ignore that, new question:", assistant: @conversation.assistant
    refute GetNextAIMessageJob.perform_now(@message.id, assistants(:samantha).id)
  end
end
