require "test_helper"

class AuthenticationTest < ActiveSupport::TestCase
  test "has associated credential" do
    assert_instance_of PasswordCredential, authentications(:keith_password).credential
  end

  test "has associated client" do
    assert_instance_of Client, authentications(:keith_password).client
  end

  test "soft delete works" do
    assert_changes "authentications(:keith_password).deleted_at" do
      authentications(:keith_password).deleted!
    end
  end
end
