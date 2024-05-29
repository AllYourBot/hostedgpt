require "test_helper"

class CredentialTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, credentials(:keith_email).user
  end

  test "has associated authentications" do
    assert_instance_of Authentication, credentials(:keith_email).authentications.first
  end
end
