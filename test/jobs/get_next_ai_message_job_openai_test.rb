require "test_helper"

class GetNextAIMessageJobOpenaiTest < ActiveJob::TestCase
  setup do
    @conversation = conversations(:greeting)
    @user = @conversation.user
    @conversation.messages.create! role: :user, content_text: "Still there?", assistant: @conversation.assistant
    @message = @conversation.latest_message_for_version(:latest)
    @test_client = TestClient::OpenAI.new(access_token: 'abc')
  end

  test "populates the latest message from the assistant" do
    assert_no_difference "@conversation.messages.reload.length" do
      TestClient::OpenAI.stub :text, "Hello" do
        TestClient::OpenAI.stub :api_response, TestClient::OpenAI.api_text_response do
          assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @conversation.assistant.id)
        end
      end
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

  test "when openai key is blank, a nice error message is displayed" do
    user = @conversation.user
    user.update!(openai_key: "")

    assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @conversation.assistant.id)
    assert_includes @conversation.latest_message_for_version(:latest).content_text, "need to enter a valid API key for OpenAI"
  end

  test "when API response key is missing, a nice error message is displayed" do
    TestClient::OpenAI.stub :text, "" do
      TestClient::OpenAI.stub :api_response, TestClient::OpenAI.api_text_response do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @conversation.assistant.id)
        assert_includes @conversation.latest_message_for_version(:latest).content_text, "a blank response"
      end
    end
  end
end
