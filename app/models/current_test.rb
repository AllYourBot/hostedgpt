require 'test_helper'

class CurrentTest < ActiveSupport::TestCase
  test "user method sets default preferences" do
    user = User.new
    current = Current.new(user)

    assert_nil user.preferences[:dark_mode]
    current.user

    assert_equal 'system', user.preferences[:dark_mode]
  end

  test "user method does not override existing preferences" do
    user = User.new
    user.preferences = { dark_mode: 'light' }
    current = Current.new(user)

    current.user

    assert_equal 'light', user.preferences[:dark_mode]
  end
end
