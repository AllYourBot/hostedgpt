require "test_helper"

class SpeechesControllerTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:keith)
    TestClient::RubyLLM::ContextDouble.reset_recordings!
  end

  test "create returns wav audio generated server-side" do
    stub_features(voice: true, use_ruby_llm: false) do
      post speech_url, params: { text: "Hello there" }, as: :json
    end

    assert_response :success
    assert_equal "audio/wav", response.media_type
    assert_equal "TEST_WAV_BYTES", response.body
    assert_equal "Hello there", TestClient::OpenAI.audio.parameters[:input]
    # The temporary dispatch: while the flag is off the legacy SDK path serves
    # the request and the RubyLLM speak double is never reached.
    assert_nil TestClient::RubyLLM::ContextDouble.last_speak_call
  end

  test "create with RubyLLM dispatch speaks through the user's OpenAI service" do
    stub_features(voice: true, use_ruby_llm: true) do
      post speech_url, params: { text: "Hello there" }, as: :json
    end

    assert_response :success
    assert_equal "audio/wav", response.media_type
    assert_equal "RUBYLLM_WAV_BYTES", response.body

    call = TestClient::RubyLLM::ContextDouble.last_speak_call
    assert_equal "Hello there", call[:text]
    assert_equal "tts-1", call[:kwargs][:model]
    assert_equal "nova", call[:kwargs][:voice]
    assert_equal "wav", call[:kwargs][:format]
    assert_equal({ speed: 1.0 }, call[:kwargs][:provider_options])
    assert_equal api_services(:keith_openai_service).effective_token, call[:openai_api_key]
  end

  test "create with RubyLLM dispatch never includes the API key in the response" do
    stub_features(voice: true, use_ruby_llm: true) do
      post speech_url, params: { text: "Hello there" }, as: :json
    end

    assert_not_includes response.body, api_services(:keith_openai_service).token
  end

  test "create with RubyLLM dispatch maps a rejected key to the actionable 422" do
    TestClient::RubyLLM::ContextDouble.speak_error_to_raise =
      ::RubyLLM::UnauthorizedError.new("Incorrect API key", response: Faraday::Response.new(status: 401, body: "denied"))

    stub_features(voice: true, use_ruby_llm: true) do
      post speech_url, params: { text: "Hello there" }, as: :json
    end

    assert_response :unprocessable_content
    assert_equal AIBackend::OpenAI.key_error_message, response.parsed_body["message"]
  end

  test "create with RubyLLM dispatch maps a rate limit to the 502 JSON" do
    TestClient::RubyLLM::ContextDouble.speak_error_to_raise =
      ::RubyLLM::RateLimitError.new("429", response: Faraday::Response.new(status: 429, body: "slow down"))

    stub_features(voice: true, use_ruby_llm: true) do
      post speech_url, params: { text: "Hello there" }, as: :json
    end

    assert_response :bad_gateway
    assert_equal "Failed to generate audio", response.parsed_body["message"]
  end

  test "create with RubyLLM dispatch maps a request rejection to the 502 JSON, not the key message" do
    TestClient::RubyLLM::ContextDouble.speak_error_to_raise =
      ::RubyLLM::BadRequestError.new("text too long", response: Faraday::Response.new(status: 400, body: "max 4096 chars"))

    stub_features(voice: true, use_ruby_llm: true) do
      post speech_url, params: { text: "Hello there" }, as: :json
    end

    assert_response :bad_gateway
    assert_equal "Failed to generate audio", response.parsed_body["message"]
  end

  test "create with RubyLLM dispatch maps an unmapped upstream 5xx to the 502 JSON" do
    TestClient::RubyLLM::ContextDouble.speak_error_to_raise =
      ::RubyLLM::ServerError.new("upstream exploded", response: Faraday::Response.new(status: 500, body: "boom"))

    stub_features(voice: true, use_ruby_llm: true) do
      post speech_url, params: { text: "Hello there" }, as: :json
    end

    assert_response :bad_gateway
    assert_equal "Failed to generate audio", response.parsed_body["message"]
  end

  test "create with RubyLLM dispatch explains a missing key when the user has no canonical OpenAI service" do
    api_services(:keith_openai_service).update!(deleted_at: Time.current)

    stub_features(voice: true, use_ruby_llm: true) do
      post speech_url, params: { text: "Hello there" }, as: :json
    end

    assert_response :unprocessable_content
    assert_equal AIBackend::OpenAI.key_error_message, response.parsed_body["message"]
    assert_nil TestClient::RubyLLM::ContextDouble.last_speak_call, "no speak call should be made without a key"
  end

  test "create never includes the API key in the response" do
    stub_features(voice: true) do
      post speech_url, params: { text: "Hello there" }, as: :json
    end

    assert_not_includes response.body, api_services(:keith_openai_service).token
  end

  test "create explains a missing key when the user has no OpenAI service" do
    api_services(:keith_openai_service).update!(deleted_at: Time.current)

    stub_features(voice: true) do
      post speech_url, params: { text: "Hello there" }, as: :json
    end

    assert_response :unprocessable_content
    assert_equal AIBackend::OpenAI.key_error_message, response.parsed_body["message"]
  end

  test "create is not found when the voice feature is off" do
    stub_features(voice: false) do
      post speech_url, params: { text: "Hello there" }, as: :json
    end

    assert_response :not_found
  end
end
