require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, people(:keith_registered).user
  end
end
