require "test_helper"

class AuthenticationTest < ActiveSupport::TestCase
  test "has associated credential" do
    assert_instance_of PasswordCredential, authentications(:keith_password_device1).credential
  end

  test "has associated client" do
    assert_instance_of Client, authentications(:keith_password_device1).client
  end

  test "soft delete works" do
    assert_changes "authentications(:keith_password_device1).deleted_at" do
      authentications(:keith_password_device1).deleted!
    end
  end
end
