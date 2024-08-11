require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "should return value of feature" do
    Setting.stub :settings, { special_key: "abc123" } do
      assert_equal "abc123", Setting.special_key
    end
  end

  test "should default to nil when feature not found" do
    assert_nil Setting.fake
  end
end
