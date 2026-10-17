require "test_helper"

# Speech: key-scoped to the canonical OpenAI service, errors mapped at the
# backend boundary, request parity with the legacy path pinned.
class AIBackend::RubyLLM::SpeechTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:attachments)
    @assistant = assistants(:keith_gpt4)
    @user = @conversation.user
    TestClient::RubyLLM::ContextDouble.reset_recordings!
  end

  test "generate_speech returns the audio bytes and records the speak call" do
    audio = AIBackend::RubyLLM.generate_speech(text: "Hello there", user: @user)

    assert_equal "RUBYLLM_WAV_BYTES", audio
    call = TestClient::RubyLLM::ContextDouble.last_speak_call
    assert_equal "Hello there", call[:text]
    assert_equal "tts-1", call[:kwargs][:model]
    assert_equal "nova", call[:kwargs][:voice]
    assert_equal "wav", call[:kwargs][:format]
    assert_equal({ speed: 1.0 }, call[:kwargs][:provider_options])
    assert_equal api_services(:keith_openai_service).effective_token, call[:openai_api_key]
  end

  test "generate_speech raises ConfigurationError without a canonical OpenAI service" do
    api_services(:keith_openai_service).update!(deleted_at: Time.current)

    assert_raises(AIBackend::RubyLLM::ConfigurationError) do
      AIBackend::RubyLLM.generate_speech(text: "Hello there", user: @user)
    end
  end

  test "generate_speech maps a rejected key to ConfigurationError" do
    TestClient::RubyLLM::ContextDouble.speak_error_to_raise =
      ::RubyLLM::UnauthorizedError.new("Incorrect API key", response: Faraday::Response.new(status: 401, body: "denied"))

    raised = assert_raises(AIBackend::RubyLLM::ConfigurationError) do
      AIBackend::RubyLLM.generate_speech(text: "Hello there", user: @user)
    end

    assert_includes raised.message, "tts-1"
  end

  test "generate_speech maps a request rejection to the 502 contract, not the key message" do
    TestClient::RubyLLM::ContextDouble.speak_error_to_raise =
      ::RubyLLM::BadRequestError.new("text too long", response: Faraday::Response.new(status: 400, body: "max 4096 chars"))

    assert_raises(::Faraday::BadRequestError) do
      AIBackend::RubyLLM.generate_speech(text: "Hello there", user: @user)
    end
  end

  test "generate_speech maps a rate limit to Faraday::TooManyRequestsError" do
    TestClient::RubyLLM::ContextDouble.speak_error_to_raise =
      ::RubyLLM::RateLimitError.new("429", response: Faraday::Response.new(status: 429, body: "slow down"))

    assert_raises(::Faraday::TooManyRequestsError) do
      AIBackend::RubyLLM.generate_speech(text: "Hello there", user: @user)
    end
  end

  test "generate_speech maps an unmapped RubyLLM error to Faraday::ServerError" do
    TestClient::RubyLLM::ContextDouble.speak_error_to_raise =
      ::RubyLLM::ServerError.new("upstream exploded", response: Faraday::Response.new(status: 500, body: "boom"))

    assert_raises(::Faraday::ServerError) do
      AIBackend::RubyLLM.generate_speech(text: "Hello there", user: @user)
    end
  end
end
