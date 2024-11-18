require "test_helper"

class ApplicationHelperTest < ActionView::TestCase

  test "only at most 2 initials" do
    assert_equal "jz", at_most_two_initials("jdz")
  end

  test "single initials allowed" do
    assert_equal "q", at_most_two_initials("q")
  end

  test "nil returns nil" do
    assert_nil at_most_two_initials(nil)
  end

  test "can have numbers" do
    assert_equal "P2", at_most_two_initials("P2")
  end

  test "does not change case" do
    assert_equal "p2", at_most_two_initials("p2")
  end

  test "returns the correct two initials when there are more than two" do
    assert_equal "kS", at_most_two_initials("kRxS")
  end

  test "can have spaces" do
    assert_equal "pQ", at_most_two_initials("p v Q")
  end

  test "truncates long names" do
    assert_equal "John D. Z. Smith ...", truncate_long_name("John D. Z. Smith Jane Doe")
  end

  test "short names are not truncated" do
    assert_equal "John D. Doe", truncate_long_name("John D. Doe")
  end

  test "handles nil" do
    assert_nil truncate_long_name(nil)
  end

end
