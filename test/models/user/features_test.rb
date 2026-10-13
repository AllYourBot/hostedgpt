require "test_helper"

class User::FeaturesTest < ActiveSupport::TestCase
  setup do
    @user = users(:keith)
  end

  test "unset choices read nil so they inherit the site default" do
    assert_nil @user.features[:use_ruby_llm]
    assert_nil @user.features[:openai_ai_backend]
  end

  test "explicit choices persist distinctly through save and reload" do
    @user.features[:use_ruby_llm] = false
    @user.features[:openai_ai_backend] = "ruby_llm"
    @user.reload

    assert_equal false, @user.features[:use_ruby_llm]
    assert_equal "ruby_llm", @user.features[:openai_ai_backend]
  end

  test "writing one choice preserves sibling choices and unrelated preferences" do
    @user.update!(dark_mode: "dark", nav_closed: true)
    @user.features[:use_ruby_llm] = true
    @user.reload

    assert_equal "dark", @user.dark_mode
    assert_equal true, @user.nav_closed
    assert_equal true, @user.features[:use_ruby_llm]

    assert_raises(KeyError) { @user.features[:registration] = true }
  end

  test "names outside the AI-backend domain raise the typo error on read and write" do
    error = assert_raises(KeyError) { @user.features[:google_tools] }
    assert_match "Did you typo a feature name?", error.message

    assert_raises(KeyError) { @user.features[:voic] }
    assert_raises(KeyError) { @user.features[:voic] = true }
  end

  test "RubyLLM is available for every chat provider identity" do
    assert User::Features.ruby_llm_available?(:openai)
    assert User::Features.ruby_llm_available?(:anthropic)
    assert User::Features.ruby_llm_available?(:gemini)
    assert User::Features.ruby_llm_available?(:groq)
    assert User::Features.ruby_llm_available?(:openrouter)
    refute User::Features.ruby_llm_available?(:brave)
  end

  test "derived backend names cover every chat provider identity, and nothing outside it" do
    assert_equal %i[openai_ai_backend anthropic_ai_backend groq_ai_backend openrouter_ai_backend gemini_ai_backend],
      User::Features.derived_backend_names

    @user.features[:groq_ai_backend] = "sdk"
    @user.reload
    assert_equal "sdk", @user.features[:groq_ai_backend]

    error = assert_raises(KeyError) { @user.features[:brave_ai_backend] = "sdk" }
    assert_match "Did you typo a feature name?", error.message
  end

  test "openrouter has its own backend choice row even though it rides the openai driver" do
    assert_includes User::Features.derived_backend_names, :openrouter_ai_backend

    @user.features[:openrouter_ai_backend] = "sdk"
    @user.reload
    assert_equal "sdk", @user.features[:openrouter_ai_backend]
  end

  test "choices written here are visible to Feature.enabled? after reload, and unset falls back to the site default" do
    @user.features[:use_ruby_llm] = true
    @user.reload

    Current.user = @user
    assert_equal true, Feature.use_ruby_llm?
  ensure
    Current.reset
  end

  test "without a current user, Feature.enabled? falls back to the site default" do
    Current.reset
    site_default = Feature.raw_features[:google_tools].to_b

    assert_equal site_default, Feature.google_tools?
  end
end
