require "test_helper"

class APIServiceTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, api_services(:keith_openai_service).user
  end

  test "has associated language_models" do
    assert_instance_of LanguageModel, api_services(:keith_openai_service).language_models.first
  end

  test "name present validated" do
    record = APIService.new(name: "")
    refute record.valid?
    assert_equal ["can't be blank"], record.errors[:name]
  end

  test "url present validated" do
    record = APIService.new(url: " ")
    refute record.valid?
    assert_equal ["can't be blank"], record.errors[:url]

    record = APIService.new(url: "")
    refute record.valid?
    assert_equal ["can't be blank"], record.errors[:url]
  end

  test "validates URL format validated" do
    record = APIService.new(url: "oh")
    refute record.valid?
    assert_equal ["is invalid"], record.errors[:url]
  end

  test "encrypts token" do
    api_service = api_services(:keith_other_service)
    old_cipher_text = api_service.ciphertext_for(:token)
    api_service.update!(token: "new secret")
    assert api_service.reload
    refute_equal old_cipher_text, api_service.ciphertext_for(:token)
    assert_equal "new secret", api_service.token
  end

  test "logo_filename" do
    assert_equal "openai_logo.svg", api_services(:keith_openai_service).logo_filename
    assert_equal "claude_logo.svg", api_services(:keith_anthropic_service).logo_filename
    assert_equal "groq_logo.svg", api_services(:keith_groq_service).logo_filename
    assert_equal "openrouter_logo.png", api_services(:keith_openrouter_service).logo_filename
    assert_equal "cheaper_inference_logo.svg", api_services(:keith_cheaper_inference_service).logo_filename
    assert_equal "google_gemini_logo.svg", api_services(:keith_gemini_service).logo_filename
    assert_nil api_services(:keith_other_service).logo_filename
  end

  test "RubyLLM is the backend for every chat provider identity, and none for brave" do
    assert_equal AIBackend::RubyLLM, language_models(:gpt_best).ai_backend
    assert_equal AIBackend::RubyLLM, language_models(:llama_3_3_70b_versatile).ai_backend
    assert_equal AIBackend::RubyLLM, language_models(:openrouter_gpt5).ai_backend
    assert_equal AIBackend::RubyLLM, language_models(:cheaper_inference_deepseek_v4_flash).ai_backend
    assert_equal AIBackend::RubyLLM, language_models(:alpaca).ai_backend
    assert_equal AIBackend::RubyLLM, language_models(:claude_best).ai_backend
    assert_equal AIBackend::RubyLLM, language_models(:gemini_flash_1_5).ai_backend
    assert_equal AIBackend::RubyLLM, language_models(:guanaco).ai_backend
    assert_nil api_services(:keith_brave_service).ai_backend
  end

  test "provider identities resolve through the canonical URL, not the raw driver" do
    assert_equal :openai, api_services(:keith_openai_service).provider_identity
    assert_equal :groq, api_services(:keith_groq_service).provider_identity
    assert_equal :openrouter, api_services(:keith_openrouter_service).provider_identity
    assert_equal :cheaper_inference, api_services(:keith_cheaper_inference_service).provider_identity
    assert_equal :anthropic, api_services(:keith_anthropic_service).provider_identity
    assert_equal :gemini, api_services(:keith_gemini_service).provider_identity
    assert_nil api_services(:keith_brave_service).provider_identity
    assert_equal :openai, api_services(:keith_other_service).provider_identity # custom-URL openai-dialect service
  end

  test "error facts resolve through the identity's own policy class, whatever transport serves the request" do
    groq = api_services(:keith_groq_service)
    openrouter = api_services(:keith_openrouter_service)

    assert_equal AIBackend::Policy::Groq.key_error_message, groq.key_error_message
    assert_equal "https://console.groq.com/keys", groq.billing_url
    assert_equal "Groq", groq.provider_name
    assert_equal AIBackend::Policy::OpenRouter.key_error_message, openrouter.key_error_message
    assert_equal "https://openrouter.ai/credits", openrouter.billing_url
    assert_equal "OpenRouter", openrouter.reload.provider_name

    cheaper_inference = api_services(:keith_cheaper_inference_service)
    assert_equal AIBackend::Policy::CheaperInference.key_error_message, cheaper_inference.key_error_message
    assert_equal "https://cheaperinference.com/", cheaper_inference.billing_url
    assert_equal "Cheaper Inference", cheaper_inference.provider_name
  end

  test "official providers require a token and custom URLs do not" do
    assert api_services(:keith_openai_service).requires_token?
    assert api_services(:keith_groq_service).requires_token?
    assert api_services(:keith_openrouter_service).requires_token?
    assert api_services(:keith_cheaper_inference_service).requires_token?
    refute api_services(:keith_other_service).requires_token?
  end

  test "the Test button reports a blank token for Groq services" do
    service = api_services(:keith_groq_service)
    service.update!(token: "")

    stub_features(default_llm_keys: false) do
      assert_equal "Error: API key (token) is blank", service.test_api_service
    end
  end

  test "the Test button reports a RubyLLM error instead of raising" do
    service = api_services(:keith_openai_service)

    TestClient::RubyLLM::Chat.stub :error_to_raise, ::RubyLLM::UnauthorizedError.new("401 bad key") do
      assert_equal "Error: 401 bad key", service.test_api_service,
        "Every model failing should surface the last error string to the Test button"
    end
  end

  test "the Test button answers through RubyLLM" do
    service = api_services(:keith_openai_service)

    TestClient::RubyLLM::Chat.stub :text, "Hi from RubyLLM" do
      assert_equal "Hi from RubyLLM", service.test_api_service, "The Test button should return the model's reply"
    end
  end

  test "the Test button probes a proxy URL in the service row's dialect" do
    service = api_services(:keith_anthropic_service)
    service.update!(url: "https://anthropic-gateway.example.com/")

    captured = nil
    original_new = TestClient::RubyLLM::Chat.method(:new)
    capture = ->(**kwargs) { captured = kwargs; original_new.call(**kwargs) }

    TestClient::RubyLLM::Chat.stub :new, capture do
      TestClient::RubyLLM::Chat.stub :text, "Hi" do
        service.test_api_service
      end
    end

    assert_equal :anthropic, captured[:provider], "The Test button should match the chat path's dialect"
    assert_equal "https://anthropic-gateway.example.com/", captured[:context].anthropic_api_base
  end

  test "cannot create record without user" do
    record = APIService.new(create_params.except(:user))
    refute record.valid?
    assert_equal ["User must exist"],  record.errors.full_messages
  end

  test "can create record" do
    assert APIService.create!(create_params)
  end

  test "soft delete also soft deletes language_models" do
    assert_difference "users(:rob).language_models.reload.count", -api_services(:rob_openai_service).language_models.count do
      assert_difference "users(:rob).api_services.reload.count", -1 do
        assert_changes "language_models(:rob_gpt).reload.deleted_at", from: nil do
          assert_changes "api_services(:rob_openai_service).deleted_at", from: nil do
            api_services(:rob_openai_service).deleted!
          end
        end
      end
    end
  end

  test "when default_llm_keys is enabled but left blank then user keys will be used" do
    api_services(:keith_openai_service).update!(token: "GPT321")
    api_services(:keith_anthropic_service).update!(token: "CLAUDE123")
    api_services(:keith_groq_service).update!(token: "GROQ123")

    stub_features(default_llm_keys: true) do
      stub_settings(default_openai_key: " ", default_anthropic_key: "", default_groq_key: nil) do
        assert_equal "GPT321", api_services(:keith_openai_service).effective_token
        assert_equal "CLAUDE123", api_services(:keith_anthropic_service).effective_token
        assert_equal "GROQ123", api_services(:keith_groq_service).effective_token
      end
    end
  end

  test "when default_llm_keys is enabled then empty user keys will fall back to default keys" do
    api_services(:keith_openai_service).update!(token: " ")
    api_services(:keith_anthropic_service).update!(token: "")
    api_services(:keith_groq_service).update!(token: nil)
    api_services(:keith_openrouter_service).update!(token: nil)
    api_services(:keith_cheaper_inference_service).update!(token: nil)

    stub_features(default_llm_keys: true) do
      stub_settings(default_openai_key: "gpt321", default_anthropic_key: "claude123", default_groq_key: "groq123", default_openrouter_key: "openrouter123", default_cheaper_inference_key: "ci123") do
        assert_equal "gpt321", api_services(:keith_openai_service).effective_token
        assert_equal "claude123", api_services(:keith_anthropic_service).effective_token
        assert_equal "groq123", api_services(:keith_groq_service).effective_token
        assert_equal "openrouter123", api_services(:keith_openrouter_service).effective_token
        assert_equal "ci123", api_services(:keith_cheaper_inference_service).effective_token
      end
    end
  end

  test "brave key falls back to BRAVE_API_KEY-derived setting even when default_llm_keys is disabled" do
    api_services(:keith_brave_service).update!(token: nil)

    stub_features(default_llm_keys: false) do
      stub_settings(default_brave_key: "brave-default-key") do
        assert_equal "brave-default-key", api_services(:keith_brave_service).effective_token
      end
    end
  end

  test "brave key prefers the user's own token over the default" do
    api_services(:keith_brave_service).update!(token: "user-brave-key")

    stub_settings(default_brave_key: "brave-default-key") do
      assert_equal "user-brave-key", api_services(:keith_brave_service).effective_token
    end
  end

  test "test_api_service returns a friendly error for drivers without an ai_backend" do
    assert_equal "Error: Testing is not supported for this API service.", api_services(:keith_brave_service).test_api_service
  end

  test "every chat provider identity maps to a RubyLLM backend" do
    {
      openai: [ :openai, APIService::URL_OPEN_AI ],
      anthropic: [ :anthropic, APIService::URL_ANTHROPIC ],
      groq: [ :openai, APIService::URL_GROQ ],
      openrouter: [ :openai, APIService::URL_OPENROUTER ],
      cheaper_inference: [ :openai, APIService::URL_CHEAPER_INFERENCE ],
      gemini: [ :gemini, APIService::URL_GEMINI ],
    }.each do |identity, (driver, url)|
      service = APIService.new(driver: driver, url: url)
      assert_equal identity, service.provider_identity
      assert_equal AIBackend::RubyLLM, service.ai_backend, "identity #{identity} must be served by RubyLLM"
    end
  end

  private

  def create_params
    {
      user: users(:taylor),
      name: "ABC Serv",
      driver: :anthropic,
      url: "http://abcdef.com/models",
      token: "access-token"
    }
  end
end
