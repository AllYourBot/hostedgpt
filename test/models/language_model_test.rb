require "test_helper"

class LanguageModelTest < ActiveSupport::TestCase
  test "is readonly?" do
    assert language_models(:gpt_best).readonly?
    assert language_models(:claude_3_sonnet).readonly?
  end

  test "ai_backend for best models" do
    assert_equal AIBackend::OpenAI, language_models(:gpt_best).ai_backend
    assert_equal AIBackend::Anthropic, language_models(:claude_best).ai_backend
  end

  test "ai_backend for Anthropic models" do
    assert_equal AIBackend::Anthropic, language_models(:claude_3_sonnet).ai_backend
    assert_equal AIBackend::Anthropic, language_models(:claude_3_opus).ai_backend
  end

  test "provider_name for Anthropic models" do
    assert_equal "claude-3-sonnet-20240229", language_models(:claude_3_sonnet).provider_name
    assert_equal "claude-3-opus-20240229", language_models(:claude_3_opus).provider_name
  end

  test "provider_name for OpenAI models" do
    assert_equal "gpt-3.5-turbo", language_models(:gpt_3_5_turbo_0125).provider_name
    assert_equal "gpt-4o", language_models(:gpt_4o).provider_name
  end

  test "ai_backend for OpenAI  models" do
    assert_equal AIBackend::OpenAI, language_models(:gpt_4o).ai_backend
    assert_equal AIBackend::OpenAI, language_models(:gpt_3_5_turbo).ai_backend
  end

  test "has assistants" do
    assert_equal 3, language_models(:gpt_4).assistants.size
    assert_equal 1, language_models(:claude_3_opus).assistants.size
    assert_equal 0, language_models(:claude_3_sonnet).assistants.size
  end
end
