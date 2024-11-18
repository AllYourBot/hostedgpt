require "test_helper"

class GetNextAIMessageJobGeminiTest < ActiveJob::TestCase
  setup do
    @conversation = conversations(:gemini_conversation)
    @user = @conversation.user
    @assistant = @conversation.assistant
    @conversation.messages.create! role: :user, content_text: "Still there?", assistant: @assistant
    @assistant.language_model.update!(supports_tools: false) # this will change the TestClient response so we want to be selective about this
    @message = @conversation.latest_message_for_version(:latest)
    @test_client = TestClient::Gemini.new(access_token: "abc")
  end

  test "populates the latest message from the assistant" do
    assert_no_difference "@conversation.messages.reload.length" do
      TestClient::Gemini.stub :text, "Hello" do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      end
    end

    assert_equal "Hello", @conversation.latest_message_for_version(:latest).content_text
  end

  test "returns early if the message id was invalid" do
    refute GetNextAIMessageJob.perform_now(@user.id, 0, @assistant.id)
  end

  test "returns early if the assistant id was invalid" do
    refute GetNextAIMessageJob.perform_now(@user.id, @message.id, 0)
  end

  test "returns early if the message was already generated" do
    @message.update!(content_text: "Hello")
    refute GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
  end

  test "returns early if the user has replied after this" do
    @conversation.messages.create! role: :user, content_text: "Ignore that, new question:", assistant: @assistant
    refute GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
  end

  test "when Gemini key is blank, a nice error message is displayed" do
    api_service = @assistant.language_model.api_service
    api_service.update!(token: "")

    assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    assert_includes @conversation.latest_message_for_version(:latest).content_text, "need to enter a valid API key for Gemini"
  end

  test "when API response key is missing, a nice error message is displayed" do
    TestClient::Gemini.stub :text, "" do
      assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      assert_includes @conversation.latest_message_for_version(:latest).content_text, "a blank response"
    end
  end
end
