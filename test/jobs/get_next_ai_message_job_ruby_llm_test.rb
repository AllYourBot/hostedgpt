require "test_helper"

class GetNextAIMessageJobRubyLLMTest < ActiveJob::TestCase
  setup do
    @conversation = conversations(:greeting)
    @user = @conversation.user
    @assistant = @conversation.assistant
    @conversation.messages.create! role: :user, content_text: "Still there?", assistant: @assistant
    @assistant.language_model.update!(supports_tools: false)
    @message = @conversation.latest_message_for_version(:latest)
  end

  test "populates the latest message from the assistant via RubyLLM" do
    stub_features(use_ruby_llm: true) do
      assert_no_difference "@conversation.messages.reload.length" do
        TestClient::RubyLLM::Chat.stub :text, "Hello from RubyLLM" do
          assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
        end
      end
    end

    assert_equal "Hello from RubyLLM", @conversation.latest_message_for_version(:latest).content_text
  end

  test "returns early if the message id was invalid" do
    stub_features(use_ruby_llm: true) do
      refute GetNextAIMessageJob.perform_now(@user.id, 0, @assistant.id)
    end
  end

  test "returns early if the assistant id was invalid" do
    stub_features(use_ruby_llm: true) do
      refute GetNextAIMessageJob.perform_now(@user.id, @message.id, 0)
    end
  end

  test "returns early if the message was already generated" do
    @message.update!(content_text: "Hello")
    stub_features(use_ruby_llm: true) do
      refute GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    end
  end

  test "returns early if the user has replied after this" do
    @conversation.messages.create! role: :user, content_text: "Ignore that, new question:", assistant: @assistant
    stub_features(use_ruby_llm: true) do
      refute GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    end
  end

  test "when API response is empty, a nice error message is displayed and the message is marked failed" do
    stub_features(use_ruby_llm: true) do
      TestClient::RubyLLM::Chat.stub :text, "" do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      end
    end

    assert_includes @conversation.latest_message_for_version(:latest).content_text, "a blank response"
    assert @message.reload.failed?, "The message should have been marked failed so a Retry button is offered"
  end

  test "when the connection drops mid-stream, the message is marked failed" do
    stub_features(use_ruby_llm: true) do
      TestClient::RubyLLM::Chat.stub_any_instance :complete, proc { |*| raise Faraday::ConnectionFailed, "connection reset by peer" } do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      end
    end

    assert_includes @message.reload.content_text, "connection error"
    assert @message.failed?, "The message should have been marked failed so a Retry button is offered"
  end

  test "a message which generated successfully is not marked failed" do
    stub_features(use_ruby_llm: true) do
      TestClient::RubyLLM::Chat.stub :text, "Hello" do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      end
    end

    assert @message.reload.not_failed?
  end
end
