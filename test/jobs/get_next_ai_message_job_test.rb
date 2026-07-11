require "test_helper"

class GetNextAIMessageJobTest < ActiveJob::TestCase
  setup do
    TestChat.reset
    @conversation = conversations(:greeting)
    @user = @conversation.user
    @assistant = @conversation.assistant
    @assistant.language_model.update!(supports_tools: false)
    @conversation.messages.create! role: :user, content_text: "Still there?", assistant: @assistant
    @message = @conversation.latest_message_for_version(:latest)
  end

  test "populates the latest message from the assistant" do
    assert_no_difference "@conversation.messages.reload.length" do
      TestChat.text = "Hello"
      assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    end

    assert_equal "Hello", @conversation.latest_message_for_version(:latest).content_text
  end

  test "populates a tool response call from the assistant and creates additional tool messages" do
    @assistant.language_model.update!(supports_tools: true)

    assert_difference "@conversation.messages.reload.length", 2 do
      TestChat.function = "helloworld_hi"
      TestChat.arguments = {name: "Keith"}.to_json
      assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    end

    @message.reload
    assert @message.content_text.blank?
    assert @message.tool_call_id.nil?
    assert @message.content_tool_calls.present?, "Assistant should have decided to call a tool"

    @new_messages = @conversation.messages.where("id > ?", @message.id).order(:created_at)

    first_new_message = @new_messages.first
    assert first_new_message.tool?
    assert_equal "Hello, Keith!".to_json, first_new_message.content_text, "First new message should have the result of calling the tool"
    assert first_new_message.tool_call_id.present?
    assert first_new_message.content_tool_calls.present?
    assert_equal @message.content_tool_calls.dig(0, :id), first_new_message.tool_call_id, "ID of tool execution should have matched decision to call the tool"
    assert first_new_message.finished?, "This message SHOULD HAVE been considered finished"

    second_new_message = @new_messages.second
    assert second_new_message.assistant?, "Second new message should be queued up for the assistant to reply"
    assert second_new_message.content_text.nil?, "The content should be nil to indicate that it hasn't even started processing"
    assert second_new_message.tool_call_id.nil?
    assert second_new_message.content_tool_calls.blank?
    refute second_new_message.finished?, "This message SHOULD NOT be considered finished yet"
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

  test "if a new message is created BEFORE job starts, it does not process" do
    @conversation.messages.create! role: :user, content_text: "You there?", assistant: @assistant

    refute GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    assert @message.content_text.blank?
    assert_nil @message.cancelled_at
  end

  test "if the cancel streaming button is clicked BEFORE job starts, it does not process" do
    @message.cancelled!

    refute GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    assert @message.content_text.blank?
    assert_not_nil @message.cancelled_at
  end

  test "if message_cancelled? starts returning true for any reason AFTER job starts, it cancels the message" do
    false_on_first_run = 0
    job = GetNextAIMessageJob.new
    job.stub(:message_cancelled?, -> {
      false_on_first_run += 1
      false_on_first_run != 1
    }) do
      TestChat.text = "Hello"
      assert_changes "@message.content_text", from: nil, to: "Hello" do
        assert_changes "@message.reload.cancelled_at", from: nil do
          assert job.perform(@user.id, @message.id, @assistant.id)
        end
      end
    end
  end

  test "when openai key is blank, a nice error message is displayed" do
    stub_features(default_llm_keys: false) do
      api_service = @assistant.language_model.api_service
      api_service.update!(token: "")

      assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
      assert_includes @conversation.latest_message_for_version(:latest).content_text, "need to enter a valid API key for OpenAI"
    end
  end

  test "when anthropic key is blank, a nice error message is displayed" do
    conversation = conversations(:hello_claude)
    conversation.assistant.language_model.update!(supports_tools: false)
    conversation.messages.create! role: :user, content_text: "Still there?", assistant: conversation.assistant
    message = conversation.latest_message_for_version(:latest)

    stub_features(default_llm_keys: false) do
      api_service = conversation.assistant.language_model.api_service
      api_service.update!(token: "")

      assert GetNextAIMessageJob.perform_now(conversation.user.id, message.id, conversation.assistant.id)
      assert_includes conversation.latest_message_for_version(:latest).content_text, "need to enter a valid API key for Anthropic"
    end
  end

  test "when gemini key is blank, a nice configuration error message is displayed" do
    conversation = conversations(:gemini_conversation)
    conversation.assistant.language_model.update!(supports_tools: false)
    conversation.messages.create! role: :user, content_text: "Still there?", assistant: conversation.assistant
    message = conversation.latest_message_for_version(:latest)

    api_service = conversation.assistant.language_model.api_service
    api_service.update!(token: "")

    assert GetNextAIMessageJob.perform_now(conversation.user.id, message.id, conversation.assistant.id)
    assert_includes conversation.latest_message_for_version(:latest).content_text, "There is a configuration error with the Gemini API Service"
  end

  test "when backend response is blank, a nice error message is displayed" do
    TestChat.blank_response = true

    assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    assert_includes @conversation.latest_message_for_version(:latest).content_text, "a blank response"
  end

  test "RubyLLM::RateLimitError displays a billing error for the provider" do
    TestChat.error_to_raise = RubyLLM::RateLimitError.new(nil, "Rate limited")

    assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    assert_includes @conversation.latest_message_for_version(:latest).content_text, "quota error"
    assert_includes @conversation.latest_message_for_version(:latest).content_text, "platform.openai.com/account/billing/overview"
  end

  test "RubyLLM::PaymentRequiredError displays a billing error" do
    TestChat.error_to_raise = RubyLLM::PaymentRequiredError.new(nil, "Pay up")

    assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    assert_includes @conversation.latest_message_for_version(:latest).content_text, "quota error"
  end

  test "RubyLLM::ServerError displays the blank response try-again message" do
    TestChat.error_to_raise = RubyLLM::ServerError.new(nil, "Server exploded")

    assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    assert_includes @conversation.latest_message_for_version(:latest).content_text, "a blank response"
  end

  test "RubyLLM::BadRequestError displays the unexpected-error message" do
    TestChat.error_to_raise = RubyLLM::BadRequestError.new(nil, "Bad request")

    assert GetNextAIMessageJob.perform_now(@user.id, @message.id, @assistant.id)
    assert_includes @conversation.latest_message_for_version(:latest).content_text, "unexpected response"
  end

  test "generic errors redact API keys from the logged message" do
    openai_key = "sk-1234567890123456789012345678901234567890ABCDEF"
    anthropic_key = "sk-ant-api03-EXAMPLEKEY1234567890abcdefghijklmnopqrstuvwxyz12"
    groq_key = "gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

    raw_message = "Something failed: #{openai_key} #{anthropic_key} #{groq_key}"
    redacted = GetNextAIMessageJob.redact_error_message(raw_message)

    refute_includes redacted, openai_key
    refute_includes redacted, anthropic_key
    refute_includes redacted, groq_key
    assert_includes redacted, "[REDACTED]"
  end
end
