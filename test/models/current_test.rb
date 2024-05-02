require 'test_helper'

class CurrentTest < ActiveSupport::TestCase
  test "user dark mode preference will be set to 'system' if preference does not exist" do
    user = User.new
    Current.user = user

    assert_nil user.preferences[:dark_mode]

    Current.user

    assert_equal 'system', user.preferences[:dark_mode]
  end

  test "user dark mode preference is not overridden" do
    user = User.new
    user.preferences = { dark_mode: 'light' }
    Current.user = user

    Current.user

    assert_equal 'light', user.preferences[:dark_mode]
  end
end
