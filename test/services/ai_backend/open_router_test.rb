require "test_helper"

class AIBackendOpenRouterTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:attachments)
    @assistant = assistants(:keith_gpt4)
    @assistant.language_model.update!(api_service: api_services(:keith_openrouter_service))
    TestClient::OpenAI.reset_recordings!
  end

  teardown do
    TestClient::OpenAI.reset_recordings!
  end

  test "key_error_message returns the recorded OpenRouter copy" do
    assert_equal "(You need to enter a valid API key for OpenRouter to use its models. Click your Profile in the bottom " +
      "left and then Settings and then **API Services**. You will find OpenRouter Key instructions.)",
      AIBackend::OpenRouter.key_error_message
  end

  test "billing_url returns the OpenRouter credits page" do
    assert_equal "https://openrouter.ai/credits", AIBackend::OpenRouter.billing_url
  end

  test "tools policy allows by inheritance from OpenAI" do
    assert AIBackend::OpenRouter.supports_tools?
  end

  test "attribution headers are attached to the client" do
    backend = AIBackend::OpenRouter.new(
      users(:keith),
      @assistant,
      @conversation,
      @conversation.latest_message_for_version(:latest)
    )

    headers = backend.client.extra_headers || {}
    assert_equal Setting.product_name.to_s, headers["X-Title"]
    assert_equal Rails.application.config.x.app_url.to_s, headers["HTTP-Referer"]
  end
end
