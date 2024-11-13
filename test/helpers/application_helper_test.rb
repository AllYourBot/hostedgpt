require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "only_user_initials returns correct initials with default limit" do
    assert_equal "JD", only_user_initials("John Doe")
    assert_equal "JS", only_user_initials("John Smith")
    assert_equal "J", only_user_initials("John")
  end

  test "only_user_initials returns correct initials with more words than limit" do
    assert_equal "AC", only_user_initials("Able Baby Commie")
    assert_equal "AC", only_user_initials("Able Baby Commie", limit: 2)
  end

  test "only_user_initials respects custom limit" do
    assert_equal "ABC", only_user_initials("Able Baby Commie", limit: 3)
    assert_equal "AB", only_user_initials("Able Baby", limit: 3)
    assert_equal "", only_user_initials("", limit: 2)
  end

  test "only_user_initials handles extra whitespace" do
    assert_equal "JD", only_user_initials("  John   Doe  ")
    assert_equal "JS", only_user_initials("John    Smith")
  end
end 