require "test_helper"

class User::PreferenceTest < ActiveSupport::TestCase
  test "boolean values within preferences get converted back and forth properly" do
    assert_nil users(:keith).preferences[:nav_closed]
    assert_nil users(:keith).preferences[:kids]
    assert_nil users(:keith).preferences[:city]

    users(:keith).update!(preferences: {
      nav_closed: true,
      kids: 2,
      city: "Austin"
    })
    users(:keith).reload

    assert users(:keith).preferences[:nav_closed]
    assert_equal 2, users(:keith).preferences[:kids]
    assert_equal "Austin", users(:keith).preferences[:city]

    users(:keith).update!(preferences: {
      nav_closed: "false",

    })

    refute users(:keith).preferences[:nav_closed]
  end

  test "dark_mode preference defaults to system and it can update user dark_mode preference" do
    new_user = User.create!(first_name: "First", last_name: "Last")
    assert_equal "system", new_user.preferences[:dark_mode]

    new_user.update!(preferences: { dark_mode: "light" })
    assert_equal "light", new_user.preferences[:dark_mode]

    new_user.update!(preferences: { dark_mode: "dark" })
    assert_equal "dark", new_user.preferences[:dark_mode]

    new_user.update!(preferences: { dark_mode: "system" })
    assert_equal "system", new_user.preferences[:dark_mode]
  end
end
