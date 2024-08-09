require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "should return value of feature" do
    Setting.stub :settings, { special_key: "abc123" } do
      assert_equal "abc123", Setting.special_key
    end
  end

  test "should raise when feature not found" do
    assert_raises SystemExit do
      Setting.fake
    end
  end
end
