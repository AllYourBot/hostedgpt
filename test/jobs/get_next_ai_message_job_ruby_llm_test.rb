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

  # Phase 3 — Anthropic + Gemini/Groq text chat

  test "populates the latest message from the assistant via RubyLLM with anthropic driver" do
    @assistant.language_model.api_service.update!(driver: "anthropic")
    stub_features(use_ruby_llm: true) do
      assert_no_difference "@conversation.messages.reload.length" do
        TestClient::RubyLLM::Chat.stub :text, "Hello from Claude via RubyLLM" do
          assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
        end
      end
    end

    assert_equal "Hello from Claude via RubyLLM", @conversation.latest_message_for_version(:latest).content_text
  end

  test "populates the latest message from the assistant via RubyLLM with gemini driver" do
    @assistant.language_model.api_service.update!(driver: "gemini")
    stub_features(use_ruby_llm: true) do
      assert_no_difference "@conversation.messages.reload.length" do
        TestClient::RubyLLM::Chat.stub :text, "Hello from Gemini via RubyLLM" do
          assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
        end
      end
    end

    assert_equal "Hello from Gemini via RubyLLM", @conversation.latest_message_for_version(:latest).content_text
  end

  test "when API response is empty with anthropic driver, a nice error message is displayed" do
    @assistant.language_model.api_service.update!(driver: "anthropic")
    stub_features(use_ruby_llm: true) do
      TestClient::RubyLLM::Chat.stub :text, "" do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      end
    end

    assert_includes @conversation.latest_message_for_version(:latest).content_text, "a blank response"
    assert @message.reload.failed?
  end

  test "when API response is empty with gemini driver, a nice error message is displayed" do
    @assistant.language_model.api_service.update!(driver: "gemini")
    stub_features(use_ruby_llm: true) do
      TestClient::RubyLLM::Chat.stub :text, "" do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      end
    end

    assert_includes @conversation.latest_message_for_version(:latest).content_text, "a blank response"
    assert @message.reload.failed?
  end

  # Phase 5 — Tool/function calling + error contract

  test "populates a tool response call and creates additional tool messages" do
    @assistant.language_model.update!(supports_tools: true)

    assert_difference "@conversation.messages.reload.length", 2 do
      stub_features(use_ruby_llm: true) do
        TestClient::RubyLLM::Chat.stub :function, "helloworld_hi" do
          TestClient::RubyLLM::Chat.stub :arguments, { name: "Keith" }.to_json do
            assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
          end
        end
      end
    end

    @message.reload
    assert @message.content_text.blank?
    assert @message.content_tool_calls.present?, "Assistant should have decided to call a tool"

    new_messages = @conversation.messages.where("id > ?", @message.id).order(:created_at)

    first_new_message = new_messages.first
    assert first_new_message.tool?
    assert_equal "Hello, Keith!".to_json, first_new_message.content_text
    assert first_new_message.tool_call_id.present?
    assert first_new_message.content_tool_calls.present?
    assert_equal @message.content_tool_calls.dig(0, :id), first_new_message.tool_call_id

    second_new_message = new_messages.second
    assert second_new_message.assistant?, "Second new message should be queued for the assistant reply"
    assert second_new_message.content_text.nil?
  end

  test "a config error renders key_error_message and marks the message failed" do
    stub_features(use_ruby_llm: true, default_llm_keys: false) do
      @assistant.language_model.api_service.update!(token: "")
      assert_no_enqueued_jobs only: GetNextAIMessageJob do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      end
    end

    assert_equal AIBackend::RubyLLM.key_error_message, @message.reload.content_text
    assert @message.failed?, "The message should have been marked failed so a Retry button is offered"
  end

  test "a rate limit error renders the quota message and marks the message failed" do
    stub_features(use_ruby_llm: true) do
      TestClient::RubyLLM::Chat.stub :error_to_raise, Faraday::TooManyRequestsError.new("quota exceeded") do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      end
    end

    assert_includes @message.reload.content_text, "a quota error"
    assert @message.failed?, "The message should have been marked failed so a Retry button is offered"
  end
end
