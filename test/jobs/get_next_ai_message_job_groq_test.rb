require "test_helper"

class GetNextAIMessageJobGroqTest < ActiveJob::TestCase
  setup do
    @conversation = conversations(:hello_groq)
    @user = @conversation.user
    @assistant = @conversation.assistant
    @conversation.messages.create! role: :user, content_text: "Still there?", assistant: @assistant
    @message = @conversation.latest_message_for_version(:latest)
  end

  test "the job rescues one unified configuration error with no per-provider remnants" do
    source = File.read(Rails.root.join("app/jobs/get_next_ai_message_job.rb"))

    ["set_openai_error", "set_groq_error", "set_anthropic_error", "set_billing_error",
     "set_generic_error", "name ==", "OpenAI::ConfigurationError", "Anthropic::ConfigurationError",
     "Gemini::Errors::ConfigurationError", "when \"OpenAI\"", "when \"Anthropic\"", "when \"Gemini\""].each do |remnant|
      refute_includes source, remnant, "the job should not contain the per-provider remnant #{remnant.inspect}"
    end

    assert_includes source, "AIBackend::ConfigurationError", "the job should rescue the unified configuration error"
  end

  test "a renamed OpenAI service still renders the canonical OpenAI key error" do
    conversation = conversations(:greeting)
    conversation.messages.create! role: :user, content_text: "Still there?", assistant: conversation.assistant
    message = conversation.latest_message_for_version(:latest)

    stub_features(default_llm_keys: false) do
      api_service = conversation.assistant.language_model.api_service
      api_service.update!(name: "My GPT Proxy", token: "")

      assert_no_enqueued_jobs only: GetNextAIMessageJob do
        assert GetNextAIMessageJob.perform_now(conversation.user.id, message.id, conversation.assistant.id)
      end

      assert_equal AIBackend::OpenAI.key_error_message, conversation.latest_message_for_version(:latest).content_text
      assert message.reload.failed?, "The message should have been marked failed so a Retry button is offered"
    end
  end

  test "a blank Groq key fails fast instead of making a doomed provider call" do
    stub_features(default_llm_keys: false) do
      @assistant.language_model.api_service.update!(token: "")

      assert_no_enqueued_jobs only: GetNextAIMessageJob do
        assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      end

      # Dispatch now routes Groq rows to their own backend, so the copy and
      # billing URL are Groq's.
      assert_equal AIBackend::Groq.key_error_message, @conversation.latest_message_for_version(:latest).content_text
      assert @message.reload.failed?, "The message should have been marked failed so a Retry button is offered"
      assert_equal 0, @message.reload.input_token_count.to_i + @message.reload.output_token_count.to_i
    end
  end

  test "a blank Groq key skips title generation before any provider call" do
    conversation = conversations(:hello_groq)
    conversation.update!(title: nil)

    stub_features(default_llm_keys: false) do
      conversation.assistant.language_model.api_service.update!(token: "")

      assert_no_enqueued_jobs only: AutotitleConversationJob do
        refute AutotitleConversationJob.perform_now(conversation.id)
      end
    end

    assert_nil conversation.reload.title
  end

  test "a custom-URL anthropic service with a nil token has the gem's own error translated to the unified one" do
    assistant = assistants(:alpaca_asst)

    api_service = assistant.language_model.api_service
    api_service.update!(token: "")

    TestClient::Anthropic.stub :new, -> (*) { raise ::Anthropic::ConfigurationError, "access_token is required" } do
      error = assert_raise(AIBackend::ConfigurationError) do
        AIBackend::Anthropic.new(assistant.user, assistant)
      end
      assert_kind_of AIBackend::ConfigurationError, error
    end
  end

  test "a quota error on a Groq row renders Groq copy with Groq's keys URL" do
    TestClient::OpenAI.stub_any_instance :chat, -> (*) { raise Faraday::TooManyRequestsError, "quota exceeded" } do
      assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    end

    expected = "(I received a quota error. Try again and if you still get this error then your API key is probably valid, but you may need to adding billing details. You are using " +
      "Groq so go here https://console.groq.com/keys and add a credit card, or if you already have one review your billing plan.)"
    assert_equal expected, @message.reload.content_text
    assert @message.failed?, "The message should have been marked failed so a Retry button is offered"
  end

  test "a renamed Groq service still gets Groq's copy, keys URL, and tools policy" do
    @assistant.language_model.api_service.update!(name: "My Fast Llama")

    assert_equal AIBackend::Groq.key_error_message, @assistant.language_model.ai_backend.key_error_message
    assert_equal "https://console.groq.com/keys", @assistant.language_model.ai_backend.billing_url
    refute @assistant.language_model.supports_tools?
  end

  test "a Groq model with backfilled tool support stays denied through the model" do
    # The 2024 supports_tools backfill set true on groq/llama rows in existing
    # databases; the backend policy keeps them denied regardless.
    @assistant.language_model.update!(supports_tools: true)

    refute @assistant.language_model.supports_tools?
  end
end
