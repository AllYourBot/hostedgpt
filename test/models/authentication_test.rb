require "test_helper"

class AuthenticationTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, authentications(:keith_email_device1).user
  end

  test "has associated credential" do
    assert_instance_of EmailCredential, authentications(:keith_email_device1).credential
  end

  test "active returns correct authentications" do
    assert_equal 2, credentials(:keith_gmail).authentications.length
    assert_equal 1, credentials(:keith_gmail).authentications.active.length
  end
end
