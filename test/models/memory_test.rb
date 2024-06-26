require "test_helper"

class MemoryTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, memories(:location).user
  end

  test "has associated message" do
    assert_instance_of Message, memories(:location).message
  end
end
