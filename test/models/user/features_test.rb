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

  test "derived backend names are valid and non-chat drivers are not" do
    @user.features[:openai_ai_backend] = "ruby_llm"
    @user.reload
    assert_equal "ruby_llm", @user.features[:openai_ai_backend]

    error = assert_raises(KeyError) { @user.features[:brave_ai_backend] = "sdk" }
    assert_match "Did you typo a feature name?", error.message
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
