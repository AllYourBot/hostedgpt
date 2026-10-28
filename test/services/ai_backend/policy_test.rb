require "test_helper"

class AIBackend::PolicyTest < ActiveSupport::TestCase
  # The policy registry is the sole owner of provider facts; the copy and URL
  # assertions below characterize the exact strings users see.

  test "the registry lists the six chat provider identities" do
    assert_equal [:openai, :anthropic, :groq, :openrouter, :cheaper_inference, :gemini], AIBackend::Policy.chat_provider_identities
  end

  test "APIService.chat_provider_identities re-bases on the registry, brave excluded" do
    assert_equal AIBackend::Policy.chat_provider_identities, APIService.chat_provider_identities
    refute_includes APIService.chat_provider_identities, :brave
  end

  test "key_error_message copies moved verbatim, read through APIService" do
    assert_equal(
      "(You need to enter a valid API key for OpenAI to use GPT. Click your Profile in the bottom " +
        "left and then Settings and then **API Services**. You will find OpenAI Key instructions.)",
      api_services(:keith_openai_service).key_error_message
    )
    assert_equal(
      "(You need to enter a valid API key for Anthropic to use Claude. Click your Profile in the bottom " +
        "left and then Settings and then **API Services**. You will find Anthropic Key instructions.)",
      api_services(:keith_anthropic_service).key_error_message
    )
    assert_equal(
      "(There is a configuration error with the Gemini API Service. Maybe you have an invalid API key? " +
        "Click your Profile in the bottom left and then Settings and then **API Services**. You will find Gemini there.)",
      api_services(:keith_gemini_service).key_error_message
    )
    assert_equal(
      "(You need to enter a valid API key for Groq to use Llama. Click your Profile in the bottom " +
        "left and then Settings and then **API Services**. You will find Groq Key instructions.)",
      api_services(:keith_groq_service).key_error_message
    )
    assert_equal(
      "(You need to enter a valid API key for OpenRouter to use its models. Click your Profile in the bottom " +
        "left and then Settings and then **API Services**. You will find OpenRouter Key instructions.)",
      api_services(:keith_openrouter_service).key_error_message
    )
    assert_equal(
      "(You need to enter a valid API key for Cheaper Inference to use its models. Click your Profile in the bottom " +
        "left and then Settings and then **API Services**. You will find Cheaper Inference Key instructions.)",
      api_services(:keith_cheaper_inference_service).key_error_message
    )
  end

  BASE_KEY_ERROR_MESSAGE = "(There is a configuration error with this API Service. Maybe you have an invalid API key? " +
    "Click your Profile in the bottom left and then Settings and then **API Services**.)"

  test "an identity without its own policy gets the base fallback copy" do
    assert_equal BASE_KEY_ERROR_MESSAGE, api_services(:keith_brave_service).key_error_message
    assert_equal BASE_KEY_ERROR_MESSAGE, AIBackend::Policy::Base.key_error_message
    # A custom-URL openai-dialect service has the openai identity, so it gets
    # OpenAI's copy, not the base fallback.
    assert_equal AIBackend::Policy::OpenAI.key_error_message, api_services(:keith_other_service).key_error_message
  end

  test "billing URLs moved verbatim, read through APIService" do
    assert_equal "https://platform.openai.com/account/billing/overview", api_services(:keith_openai_service).billing_url
    assert_equal "https://console.anthropic.com/settings/plans", api_services(:keith_anthropic_service).billing_url
    assert_equal "https://aistudio.google.com/app/apikey", api_services(:keith_gemini_service).billing_url
    assert_equal "https://console.groq.com/keys", api_services(:keith_groq_service).billing_url
    assert_equal "https://openrouter.ai/credits", api_services(:keith_openrouter_service).billing_url
    assert_equal "https://cheaperinference.com/", api_services(:keith_cheaper_inference_service).billing_url
    assert_nil api_services(:keith_brave_service).billing_url
  end

  test "provider_name keeps the AI fallback for identities without a policy" do
    assert_equal "OpenAI", api_services(:keith_openai_service).provider_name
    assert_equal "AI", api_services(:keith_brave_service).provider_name
    assert_equal "OpenAI", api_services(:keith_other_service).provider_name
  end

  test "tool policy: Groq denies, every other identity allows" do
    refute AIBackend::Policy::Groq.supports_tools?
    assert AIBackend::Policy::OpenAI.supports_tools?
    assert AIBackend::Policy::Anthropic.supports_tools?
    assert AIBackend::Policy::Gemini.supports_tools?
    assert AIBackend::Policy::OpenRouter.supports_tools?
    assert AIBackend::Policy::CheaperInference.supports_tools?
  end

  test "LanguageModel#supports_tools? reads the identity's policy" do
    assert language_models(:gpt_4o).supports_tools? # openai policy allows
    refute language_models(:llama_3_3_70b_versatile).supports_tools? # Groq policy denies

    model = language_models(:gpt_4o)
    model.supports_tools = false
    refute model.supports_tools?

    model.update!(api_service: api_services(:keith_brave_service), supports_tools: true)
    refute model.supports_tools?
  end

  test "OpenRouter attribution headers are identical to today's output" do
    assert_equal %w[HTTP-Referer X-Title], AIBackend::Policy::OpenRouter.attribution_headers.keys
    assert_empty AIBackend::Policy::OpenAI.attribution_headers
  end

  test "error_detail names the model and excerpts a sanitized response" do
    # The key tail is 42 chars, not 40 — an exactly-40-char redaction pattern
    # would leave a cleartext "01" behind, so this exact assertion bites. The
    # y/z padding around the key (separated by spaces) exercises the excerpt
    # cap: the full body never survives.
    body = ("y" * 100) + " Error: bad key sk-abc123def456ghi789jkl012mno345pqr678stu901 " + ("z" * 300)
    error = ::RubyLLM::UnauthorizedError.new("Unauthorized", response: Faraday::Response.new(status: 401, body: body))

    detail = AIBackend::RubyLLM.error_detail(error, model: "claude-bad")

    assert_includes detail, "model: claude-bad"
    assert_includes detail, "status: 401"
    assert_equal "model: claude-bad, status: 401, body: #{ "y" * 100 } Error: bad key sk-#{ "*" * 40 } #{ "z" * 40 }", detail
    assert_not_includes detail, body
    assert_not_includes detail, "sk-abc123def456ghi789jkl012mno345pqr678stu901"
  end

  test "error_detail redacts Groq and Gemini key shapes too" do
    error = ::RubyLLM::UnauthorizedError.new("Unauthorized", response: Faraday::Response.new(status: 401, body: "denied gsk_ABCDEF123xyz AIzaABCDEF123xyz"))

    detail = AIBackend::RubyLLM.error_detail(error, model: "m")

    assert_not_includes detail, "gsk_ABCDEF123xyz"
    assert_not_includes detail, "AIzaABCDEF123xyz"
    assert_includes detail, "gsk_#{ "*" * 40 }"
    assert_includes detail, "AIza#{ "*" * 40 }"
  end

  test "error_detail redacts Cheaper Inference key shapes too" do
    error = ::RubyLLM::UnauthorizedError.new("Unauthorized", response: Faraday::Response.new(status: 401, body: "denied ci_live_ABCDEF123xyz"))

    detail = AIBackend::RubyLLM.error_detail(error, model: "m")

    assert_not_includes detail, "ci_live_ABCDEF123xyz"
    assert_includes detail, "ci_live_#{ "*" * 40 }"
  end

  test "error_detail names the model even when the error carries no response" do
    error = ::RubyLLM::UnauthorizedError.new("401 bad key")

    assert_equal "model: gpt-4o", AIBackend::RubyLLM.error_detail(error, model: "gpt-4o")
  end

  test "the mapped chat errors carry the model name and excerpt" do
    @assistant = assistants(:keith_claude3)
    @user = @assistant.user
    long_body = "y" * 300
    error = ::RubyLLM::UnauthorizedError.new("Invalid API key - check your credentials", response: Faraday::Response.new(status: 401, body: long_body))

    backend = AIBackend::RubyLLM.new(@user, @assistant)
    TestClient::RubyLLM::Chat.stub :error_to_raise, error do
      raised = assert_raises(AIBackend::RubyLLM::ConfigurationError) do
        backend.get_oneoff_message("You are helpful", ["Hi"])
      end

      assert_includes raised.message, "model: #{@assistant.language_model.api_name}"
      assert_includes raised.message, "status: 401"
      assert_not_includes raised.message, long_body
    end
  end
end
