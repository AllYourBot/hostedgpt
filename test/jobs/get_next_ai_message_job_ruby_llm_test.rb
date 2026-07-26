require "test_helper"

class GetNextAIMessageJobRubyLLMTest < ActiveJob::TestCase
  include OptionsHelpers
  include RubyLLMTestHelpers

  setup do
    stub_features(rubyllm: true)

    @conversation = conversations(:greeting)
    @user = @conversation.user
    @assistant = @conversation.assistant
    @assistant.language_model.update!(supports_tools: false)
    @conversation.messages.create! role: :user, content_text: "Are you still there?", assistant: @assistant
    @message = @conversation.latest_message_for_version(:latest)
    TestClient::RubyLLM.function_stubbed = false
  end

  teardown do
    TestClient::RubyLLM.function_stubbed = false
  end

  test "flag on: streaming text saves the message correctly" do
    TestClient::RubyLLM.stub :text, "Hello from RubyLLM" do
      stub_rubyllm_client do
        assert_changes "@message.reload.content_text", from: nil, to: "Hello from RubyLLM" do
          assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
        end
      end
    end
  end

  test "flag on: AIBackend::RubyLLM::ConfigurationError rescued with user-friendly message" do
    TestClient::RubyLLM::Chat.stub_any_instance :complete, ->(*) { raise RubyLLM::UnauthorizedError, "bad key" } do
      stub_rubyllm_client do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)

        @message.reload
        assert_includes @message.content_text, "configuration error"
        assert_includes @message.content_text, "OpenAI"
      end
    end
  end

  test "flag on: AIBackend::RubyLLM::RateLimitError rescued with billing message" do
    TestClient::RubyLLM::Chat.stub_any_instance :complete, ->(*) { raise RubyLLM::RateLimitError, "slow down" } do
      stub_rubyllm_client do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)

        @message.reload
        assert_includes @message.content_text, "quota error"
      end
    end
  end

  test "flag on: blank response raises Faraday::ParsingError and shows blank response message" do
    TestClient::RubyLLM.stub :text, "" do
      stub_rubyllm_client do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)

        @message.reload
        assert_includes @message.content_text, "blank response"
      end
    end
  end

  test "flag off: existing TestClient::OpenAI path unchanged" do
    stub_features(rubyllm: false) do
      TestClient::OpenAI.stub :text, "Hello from OpenAI" do
        assert_changes "@message.reload.content_text", from: nil, to: "Hello from OpenAI" do
          assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
        end
      end
    end
  end

  test "flag on: tool calling creates tool messages and enqueues re-entry job" do
    @assistant.language_model.update!(supports_tools: true)
    TestClient::RubyLLM.function_stubbed = true

    TestClient::RubyLLM.stub :function, "helloworld_hi" do
      TestClient::RubyLLM.stub :arguments, { name: "Keith" }.to_json do
        stub_rubyllm_client do
          assert_difference "@conversation.messages.reload.length", 2 do
            assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
          end
          assert_enqueued_with(job: GetNextAIMessageJob)
        end
      end
    end

    @message.reload
    assert @message.content_text.blank?
    assert @message.content_tool_calls.present?, "Assistant should have decided to call a tool"

    new_messages = @conversation.messages.where("id > ?", @message.id).order(:created_at)
    tool_message = new_messages.first
    assert tool_message.tool?
    assert_equal "Hello, Keith!".to_json, tool_message.content_text

    assistant_reply = new_messages.second
    assert assistant_reply.assistant?
    assert assistant_reply.content_text.nil?
  end

  test "flag on: RateLimitError shows correct billing URL for OpenAI driver" do
    TestClient::RubyLLM::Chat.stub_any_instance :complete, ->(*) { raise RubyLLM::RateLimitError, "slow down" } do
      stub_rubyllm_client do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)

        @message.reload
        assert_includes @message.content_text, "platform.openai.com"
      end
    end
  end

  test "flag on: RateLimitError shows Anthropic billing URL for anthropic driver" do
    anthropic_assistant = assistants(:keith_claude3)
    conversation = anthropic_assistant.conversations.create!(user: @user)
    conversation.messages.create! role: :user, content_text: "Hello", assistant: anthropic_assistant
    msg = conversation.latest_message_for_version(:latest)

    TestClient::RubyLLM::Chat.stub_any_instance :complete, ->(*) { raise RubyLLM::RateLimitError, "slow down" } do
      stub_rubyllm_client do
        assert GetNextAIMessageJob.perform_now(@user.id, msg.id, anthropic_assistant.id)

        msg.reload
        assert_includes msg.content_text, "console.anthropic.com"
      end
    end
  end
end
