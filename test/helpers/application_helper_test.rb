require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  
test "only at most 2 initials with default limit" do
    assert_equal "jz", only_user_initials("jdz")
    assert_equal "pl", only_user_initials("Plllll")
  end
  

  test "single initials allowed" do
    assert_equal "q", only_user_initials("q")
  end  

  test "should down case" do
    assert_equal "q", only_user_initials("Q")
  end    

  test "can have numbers" do
    assert_equal "p2", only_user_initials("Pvv2")
  end  

  test "can gave spaces" do
    assert_equal "pq", only_user_initials("P vv qQ")
  end  

end 