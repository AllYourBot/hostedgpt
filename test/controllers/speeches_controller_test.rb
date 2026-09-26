require "test_helper"

class SpeechesControllerTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:keith)
  end

  test "create returns wav audio generated server-side" do
    stub_features(voice: true) do
      post speech_url, params: { text: "Hello there" }, as: :json
    end

    assert_response :success
    assert_equal "audio/wav", response.media_type
    assert_equal "TEST_WAV_BYTES", response.body
    assert_equal "Hello there", TestClient::OpenAI.audio.parameters[:input]
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
