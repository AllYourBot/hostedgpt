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

  test "both ai_backends are specified for best models" do
    assert_equal AIBackend::OpenAI, language_models(:gpt_best).ai_backend
    assert_equal AIBackend::Anthropic, language_models(:claude_best).ai_backend
  end

  test "both ai_backends can be specified for user models" do
    assert_equal AIBackend::Anthropic, language_models(:alpaca).ai_backend
    assert_equal AIBackend::OpenAI, language_models(:guanaco).ai_backend
  end

  test "cannot create record without user" do
    record = APIService.new(create_params.except(:user))
    refute record.valid?
    assert_equal ["User must exist"],  record.errors.full_messages
  end

  test "can create record" do
    APIService.create!(create_params)
    assert true # because we have to have an assertion in a test
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

    stub_features(default_llm_keys: true) do
      stub_settings(default_openai_key: "gpt321", default_anthropic_key: "claude123", default_groq_key: "groq123") do
        assert_equal "gpt321", api_services(:keith_openai_service).effective_token
        assert_equal "claude123", api_services(:keith_anthropic_service).effective_token
        assert_equal "groq123", api_services(:keith_groq_service).effective_token
      end
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
