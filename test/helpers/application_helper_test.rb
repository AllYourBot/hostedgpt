require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "only at most 2 initials with default limit" do
    assert_equal "JZ", only_user_initials("jdz")
    assert_equal "PL", only_user_initials("Plllll")
  end
  test "single initials allowed" do
    assert_equal "Q", only_user_initials("q")
  end  

  test "can have numbers" do
    assert_equal "P2", only_user_initials("Pvv2")
  end  

end 