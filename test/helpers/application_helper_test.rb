require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  
test "only at most 2 initials with default limit" do
    assert_equal "jz", only_two_initials("jdz")
  end
  

  test "single initials allowed" do
    assert_equal "q", only_two_initials("q")
  end  


  test "nil returns nil" do
    assert_nil only_two_initials(nil)
  end   

  test "can have numbers" do
    assert_equal "P2", only_two_initials("PV2")
  end  

  test "does not change case" do
    assert_equal "p2", only_two_initials("pV2")
  end  

  test "can have spaces" do
    assert_equal "pQ", only_two_initials("p v Q")
  end  

end 