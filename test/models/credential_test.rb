require "test_helper"

class CredentialTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, credentials(:keith_password).user
  end

  test "has associated authentications" do
    assert_instance_of Authentication, credentials(:keith_password).authentications.first
  end

  test "has associated authentications_including_deleted" do
    assert_instance_of Authentication, credentials(:keith_password).authentications_including_deleted.first
  end

  test "associations are deleted upon destroy" do
    assert_difference "Authentication.count", -credentials(:keith_password).authentications_including_deleted.count do
      credentials(:keith_password).destroy
    end
  end
end
