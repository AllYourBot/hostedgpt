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
    assert_no_difference "@conversation.messages.reload.length" do
      TestClient::RubyLLM::Chat.stub :text, "Hello from RubyLLM" do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      end
    end

    assert_equal "Hello from RubyLLM", @conversation.latest_message_for_version(:latest).content_text
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

  test "when API response is empty, a nice error message is displayed and the message is marked failed" do
    TestClient::RubyLLM::Chat.stub :text, "" do
      assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    end

    assert_includes @conversation.latest_message_for_version(:latest).content_text, "a blank response"
    assert @message.reload.failed?, "The message should have been marked failed so a Retry button is offered"
  end

  test "when the connection drops mid-stream, the message is marked failed" do
    TestClient::RubyLLM::Chat.stub_any_instance :generate, proc { |*| raise Faraday::ConnectionFailed, "connection reset by peer" } do
      assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    end

    assert_includes @message.reload.content_text, "connection error"
    assert @message.failed?, "The message should have been marked failed so a Retry button is offered"
  end

  test "a message which generated successfully is not marked failed" do
    TestClient::RubyLLM::Chat.stub :text, "Hello" do
      assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    end

    assert @message.reload.not_failed?
  end

  test "a reply cut off at the output token limit is saved and marked truncated" do
    stub_features(use_ruby_llm: true) do
      TestClient::RubyLLM::Chat.stub :text, "The first half of a long answer" do
        TestClient::RubyLLM::Chat.stub :finish_reason, :max_tokens do
          assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
        end
      end
    end

    assert_equal "The first half of a long answer", @message.reload.content_text, "The partial reply should still be saved"
    assert @message.truncated?, "The message should have been marked truncated so a Continue button is offered"
    assert @message.not_failed?, "A truncated reply is not a failure, so it should not offer Retry"
  end

  test "a reply which finished on its own is not marked truncated" do
    stub_features(use_ruby_llm: true) do
      TestClient::RubyLLM::Chat.stub :text, "Hello" do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      end
    end

    assert @message.reload.not_truncated?, "A reply which ended normally should not offer Continue"
  end

  # Phase 3 — Anthropic + Gemini/Groq text chat

  test "populates the latest message from the assistant via RubyLLM with anthropic driver" do
    @assistant.language_model.api_service.update!(driver: "anthropic")
    assert_no_difference "@conversation.messages.reload.length" do
      TestClient::RubyLLM::Chat.stub :text, "Hello from Claude via RubyLLM" do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      end
    end

    assert_equal "Hello from Claude via RubyLLM", @conversation.latest_message_for_version(:latest).content_text
  end

  test "populates the latest message from the assistant via RubyLLM with gemini driver" do
    @assistant.language_model.api_service.update!(driver: "gemini")
    assert_no_difference "@conversation.messages.reload.length" do
      TestClient::RubyLLM::Chat.stub :text, "Hello from Gemini via RubyLLM" do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      end
    end

    assert_equal "Hello from Gemini via RubyLLM", @conversation.latest_message_for_version(:latest).content_text
  end

  test "when API response is empty with anthropic driver, a nice error message is displayed" do
    @assistant.language_model.api_service.update!(driver: "anthropic")
    TestClient::RubyLLM::Chat.stub :text, "" do
      assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    end

    assert_includes @conversation.latest_message_for_version(:latest).content_text, "a blank response"
    assert @message.reload.failed?
  end

  test "when API response is empty with gemini driver, a nice error message is displayed" do
    @assistant.language_model.api_service.update!(driver: "gemini")
    TestClient::RubyLLM::Chat.stub :text, "" do
      assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    end

    assert_includes @conversation.latest_message_for_version(:latest).content_text, "a blank response"
    assert @message.reload.failed?
  end

  # Phase 5 — Tool/function calling + error contract

  test "populates a tool response call and creates additional tool messages" do
    @assistant.language_model.update!(supports_tools: true)

    assert_difference "@conversation.messages.reload.length", 2 do
      TestClient::RubyLLM::Chat.stub :function, "helloworld_hi" do
        TestClient::RubyLLM::Chat.stub :arguments, { name: "Keith" }.to_json do
          assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
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

  test "the assistant's tool-call signature persists for replay on the follow-up request" do
    @assistant.language_model.update!(supports_tools: true)

    TestClient::RubyLLM::Chat.stub :function, "helloworld_hi" do
      TestClient::RubyLLM::Chat.stub :arguments, { name: "Keith" }.to_json do
        TestClient::RubyLLM::Chat.stub :thought_signature, "sig-gemini-42" do
          assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
        end
      end
    end

    assert_equal "sig-gemini-42", @message.reload.content_tool_calls.dig(0, :thought_signature),
      "The signature must be persisted so it can be replayed on the follow-up request"
  end

  test "an image tool call attaches the generated image and redacts the base64 payload" do
    @assistant.language_model.update!(supports_tools: true)

    assert_difference "@conversation.messages.reload.length", 2 do
      TestClient::RubyLLM::Chat.stub :function, "image_generate_an_image" do
        TestClient::RubyLLM::Chat.stub :arguments, { image_generation_prompt: "A cartoon cat" }.to_json do
          AIBackend::RubyLLM.stub :generate_image, { b64_json: "BASE64_IMAGE_PAYLOAD", model: "gpt-image-1", provider: "OpenAI" } do
            assert_enqueued_with(job: GetNextAIMessageJob) do
              assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
            end
          end
        end
      end
    end

    tool_message, assistant_reply = @conversation.messages.reload.order(:index).last(2)
    assert_equal "tool", tool_message.role
    assert_includes tool_message.content_text, "prompt_given"
    refute_includes tool_message.content_text, "BASE64_IMAGE_PAYLOAD" # the payload is redacted from the saved tool message

    document = assistant_reply.documents.sole
    assert_equal "generated.png", document.filename
    assert_equal "image/png", document.file.content_type
  end

  test "several image tool calls in one turn attach every generated image to the reply" do
    @assistant.language_model.update!(supports_tools: true)
    tool_messages = %w[call_dog_1 call_dog_2].map do |tool_call_id|
      {
        role: "tool",
        tool_call_id:,
        content_tool_calls: { id: tool_call_id, function: { name: "image_generate_an_image", arguments: { image_generation_prompt: "A cartoon dog" } } },
        content: { prompt_given: "A cartoon dog", json_of_generated_image: Base64.strict_encode64("PNG #{tool_call_id}") }.to_json,
      }
    end

    TestClient::RubyLLM::Chat.stub :function, "image_generate_an_image" do
      TestClient::RubyLLM::Chat.stub :arguments, { image_generation_prompt: "A cartoon dog" }.to_json do
        AIBackend::RubyLLM.stub :get_tool_messages_by_calling, tool_messages do
          assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id), "The job should finish"
        end
      end
    end

    assistant_reply = @conversation.messages.reload.order(:index).last
    assert_equal ["PNG call_dog_1", "PNG call_dog_2"], assistant_reply.documents.map { |document| document.file.download }.sort, "Both generated images should be attached to the reply"
  end

  test "a config error renders key_error_message and marks the message failed" do
    stub_features(default_llm_keys: false) do
      @assistant.language_model.api_service.update!(token: "")
      assert_no_enqueued_jobs only: GetNextAIMessageJob do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      end
    end

    # The facts come from the identity's policy class (Policy::OpenAI), not the
    # transport class, so the user sees OpenAI's copy, not the generic one.
    assert_equal AIBackend::Policy::OpenAI.key_error_message, @message.reload.content_text
    assert @message.failed?, "The message should have been marked failed so a Retry button is offered"
  end

  test "a Groq identity conversation renders Groq's key error copy and marks the message failed" do
    conversation = conversations(:hello_groq)
    conversation.messages.create! role: :user, content_text: "Still there?", assistant: conversation.assistant
    message = conversation.latest_message_for_version(:latest)

    stub_features(default_llm_keys: false) do
      conversation.assistant.language_model.api_service.update!(token: "")

      assert_no_enqueued_jobs only: GetNextAIMessageJob do
        assert GetNextAIMessageJob.perform_now(conversation.user.id, message.id, conversation.assistant.id)
      end
    end

    # The facts come from the identity's policy class (Policy::Groq), not the transport.
    assert_equal AIBackend::Policy::Groq.key_error_message, conversation.latest_message_for_version(:latest).content_text
    assert message.reload.failed?, "The message should have been marked failed so a Retry button is offered"
    assert_equal 0, message.input_token_count.to_i + message.output_token_count.to_i
  end

  test "a rate limit error renders the quota message with the identity's billing URL and marks the message failed" do
    TestClient::RubyLLM::Chat.stub :error_to_raise, Faraday::TooManyRequestsError.new("quota exceeded") do
      assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    end

    # The quota copy speaks for the service's identity (Policy::OpenAI), not the
    # transport: OpenAI's name and billing URL, not "RubyLLM" and nil.
    assert_includes @message.reload.content_text, "a quota error"
    assert_includes @message.content_text, "You are using OpenAI so go here https://platform.openai.com/account/billing/overview"
    assert @message.failed?, "The message should have been marked failed so a Retry button is offered"
  end

  test "saves the thinking and its signature alongside the reply" do
    @assistant.language_model.api_service.update!(driver: "anthropic")
    @assistant.language_model.update!(supports_thinking: true)
    thinking = ::RubyLLM::Thinking.build(text: "Let me work through this...", signature: "sig-abc")

    TestClient::RubyLLM::Chat.stub :thinking, thinking do
      TestClient::RubyLLM::Chat.stub :text, "The answer is 42." do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      end
    end

    @message.reload
    assert_equal "The answer is 42.", @message.content_text
    assert_equal "Let me work through this...", @message.thinking_text
    assert_equal "sig-abc", @message.thinking_signature
  end
end
