require "test_helper"

class LanguageModelTest < ActiveSupport::TestCase
  test "has associated assistant" do
    assert_instance_of Assistant, language_models(:gpt_4).assistants.first
  end

  test "is readonly?" do
    assert language_models(:gpt_best).readonly?
    assert language_models(:claude_3_sonnet).readonly?
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
end
