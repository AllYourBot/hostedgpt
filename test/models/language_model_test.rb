require "test_helper"

class LanguageModelTest < ActiveSupport::TestCase
  test "has associated assistant" do
    assert_instance_of Assistant, language_models(:gpt_4o).assistants.first
  end

  test "is readonly?" do
    assert language_models(:gpt_best).readonly?
    assert language_models(:claude_best).readonly?
  end

  test "supports_images?" do
    assert language_models(:gpt_best).supports_images?
    refute language_models(:gpt_3_5_turbo).supports_images?
  end

  test "provider_name for Anthropic models" do
    assert_equal "claude-3-sonnet-20240229", language_models(:claude_3_sonnet).provider_name
    assert_equal "claude-3-opus-20240229", language_models(:claude_3_opus).provider_name
  end

  test "provider_name for OpenAI models" do
    assert_equal "gpt-3.5-turbo", language_models(:gpt_3_5_turbo_0125).provider_name
    assert_equal "gpt-4o", language_models(:gpt_4o).provider_name
  end

  test "ai_backend for best models" do
    assert_equal AIBackend::OpenAI, language_models(:gpt_best).ai_backend
    assert_equal AIBackend::Anthropic, language_models(:claude_best).ai_backend
  end

  test "provider_name for best models" do
    assert_equal "gpt-4o-2024-05-13", language_models(:gpt_best).provider_name
    assert_equal "claude-3-opus-20240229", language_models(:claude_best).provider_name
  end

  test "provider_name for non-best models" do
    assert_equal "gpt-4o", language_models(:gpt_4o).provider_name
    assert_equal "claude-3-opus-20240229", language_models(:claude_3_opus_20240229).provider_name
  end
end
