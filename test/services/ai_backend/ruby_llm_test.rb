require "test_helper"

class AIBackend::RubyLLMTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:attachments)
    @assistant = assistants(:keith_gpt4)
    @openai_service = api_services(:keith_openai_service)
    @anthropic_service = api_services(:keith_anthropic_service)
    @gemini_service = api_services(:keith_gemini_service)
  end

  test "supports_driver? returns false for all drivers in Phase 1" do
    refute AIBackend::RubyLLM.supports_driver?("openai")
    refute AIBackend::RubyLLM.supports_driver?("anthropic")
    refute AIBackend::RubyLLM.supports_driver?("gemini")
  end

  test "APIService#ai_backend returns old OpenAI class when feature flag is off" do
    assert_equal AIBackend::OpenAI, @openai_service.ai_backend
  end

  test "APIService#ai_backend returns old Anthropic class when feature flag is off" do
    assert_equal AIBackend::Anthropic, @anthropic_service.ai_backend
  end

  test "APIService#ai_backend returns old Gemini class when feature flag is off" do
    assert_equal AIBackend::Gemini, @gemini_service.ai_backend
  end

  test "APIService#ai_backend still returns old classes even with flag on since supports_driver? is false" do
    stub_features(use_ruby_llm: true) do
      assert_equal AIBackend::OpenAI, @openai_service.ai_backend
      assert_equal AIBackend::Anthropic, @anthropic_service.ai_backend
      assert_equal AIBackend::Gemini, @gemini_service.ai_backend
    end
  end

  test "client returns TestClient::RubyLLM in test environment" do
    assert_equal TestClient::RubyLLM, AIBackend::RubyLLM.client
  end
end
