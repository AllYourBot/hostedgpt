require "test_helper"

class GetNextAIMessageJobAnthropicTest < ActiveJob::TestCase
  setup do
    TestChat.reset
    @conversation = conversations(:hello_claude)
    @user = @conversation.user
    @conversation.assistant.language_model.update!(supports_tools: false)
    @conversation.messages.create! role: :user, content_text: "Still there?", assistant: @conversation.assistant
    @message = @conversation.latest_message_for_version(:latest)
  end

  test "populates the latest message from the assistant" do
    assert_no_difference "@conversation.messages.reload.length" do
      TestChat.text = "Hello"
      assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @conversation.assistant.id)
    end

    assert_equal "Hello", @conversation.latest_message_for_version(:latest).content_text
  end

  test "returns early if the message id was invalid" do
    refute GetNextAIMessageJob.perform_now(@user.id, 0, @conversation.assistant.id)
  end

  test "returns early if the assistant id was invalid" do
    refute GetNextAIMessageJob.perform_now(@user.id, @message.id, 0)
  end

  test "returns early if the message was already generated" do
    @message.update!(content_text: "Hello")
    refute GetNextAIMessageJob.perform_now(@user.id, @message.id, @conversation.assistant.id)
  end

  test "returns early if the user has replied after this" do
    @conversation.messages.create! role: :user, content_text: "Ignore that, new question:", assistant: @conversation.assistant
    refute GetNextAIMessageJob.perform_now(@user.id, @message.id, @conversation.assistant.id)
  end

  test "when anthropic key is blank, a nice error message is displayed" do
    stub_features(default_llm_keys: false) do
      api_service = @conversation.assistant.language_model.api_service
      api_service.update!(token: "")

      assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @conversation.assistant.id)
      assert_includes @conversation.latest_message_for_version(:latest).content_text, "need to enter a valid API key for Anthropic"
    end
  end

  test "when API response key is missing, a nice error message is displayed" do
    TestChat.text = ""
    assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @conversation.assistant.id)
    assert_includes @conversation.latest_message_for_version(:latest).content_text, "a blank response"
  end
end
