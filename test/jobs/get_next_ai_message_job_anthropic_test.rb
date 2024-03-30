require "test_helper"

class GetNextAIMessageJobAnthropicTest < ActiveJob::TestCase
  setup do
    @conversation = conversations(:hello_claude)
    @message = @conversation.messages.create! role: :assistant, content_text: "", assistant: @conversation.assistant
    @test_client = TestClients::Anthropic.new(access_token: 'abc')
  end

  test "populates the latest message from the assistant" do
    assert_no_difference "@conversation.messages.reload.length" do
      assert GetNextAIMessageJob.perform_now(@message.id, @conversation.assistant.id)
    end

    message_text = @test_client.messages
    assert_equal message_text, @conversation.latest_message.content_text
  end

  test "re-populates an earlier message from the assistant if it was provided and marked as re-requested" do
    messages(:claude_replying).update!(rerequested_at: Time.current, content_text: nil)

    assert_no_difference "@conversation.messages.reload.length" do
      assert GetNextAIMessageJob.perform_now(messages(:claude_replying).id, @conversation.assistant.id)
    end

    message_text = @test_client.messages
    assert_equal message_text, messages(:claude_replying).reload.content_text
    assert_not_equal message_text, @conversation.latest_message.content_text
  end

  test "returns early if attempting to re-populate an earlier message from the assistant if it was provided but NOT marked as re-requested" do
    messages(:claude_replying).update!(content_text: nil)

    assert_no_difference "@conversation.messages.reload.length" do
      refute GetNextAIMessageJob.perform_now(messages(:claude_replying).id, @conversation.assistant.id)
    end

    message_text = @test_client.messages
    assert_not_equal message_text, messages(:claude_replying).reload.content_text
    assert_not_equal message_text, @conversation.latest_message.content_text
  end

  test "returns early if the message id was invalid" do
    refute GetNextAIMessageJob.perform_now(0, @conversation.assistant.id)
  end

  test "returns early if the assistant id was invalid" do
    refute GetNextAIMessageJob.perform_now(@message.id, 0)
  end

  test "returns early if the message was already generated" do
    @message.update!(content_text: "Hello")
    refute GetNextAIMessageJob.perform_now(@message.id, @conversation.assistant.id)
  end

  test "returns early if the user has replied after this" do
    @conversation.messages.create! role: :user, content_text: "Ignore that, new question:", assistant: @conversation.assistant
    refute GetNextAIMessageJob.perform_now(@message.id, @conversation.assistant.id)
  end

  test "when openai key is blank, a nice error message is displayed" do
    user = conversations(:greeting).user
    user.update!(anthropic_key: "")

    assert_no_difference "@conversation.messages.reload.length" do
      assert GetNextAIMessageJob.perform_now(@message.id, @conversation.assistant.id)
    end

    assert_includes @conversation.latest_message.content_text, "need to enter a valid API key for Anthropic"
  end
end
