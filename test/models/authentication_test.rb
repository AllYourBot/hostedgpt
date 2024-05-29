require "test_helper"

class AuthenticationTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, authentications(:keith_email).user
  end

  test "has associated credential" do
    assert_instance_of EmailCredential, authentications(:keith_email).credential
  end
end
