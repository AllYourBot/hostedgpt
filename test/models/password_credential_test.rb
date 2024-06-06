require "test_helper"

class PasswordCredentialTest < ActiveSupport::TestCase
  test "needs to have a password" do
    minimum_credential = users(:rob).credentials.new(type: "PasswordCredential", password: "abc123")
    assert minimum_credential.valid?, "We were unable to verify the minimum password credential"

    minimum_credential.password = nil
    refute minimum_credential.valid?, "The password should be required"
  end

  test "password is not required when making updates" do
    credentials(:keith_password).last_authenticated_at = Time.current
    assert credentials(:keith_password).valid?, "The password should be allowed to be blank when changing other details"
  end

  test "it can update the password" do
    old_password_hash = credentials(:keith_password).password_digest
    credentials(:keith_password).update(password: "password")
    assert credentials(:keith_password).valid?
    refute_equal old_password_hash, credentials(:keith_password).password_digest
  end

  test "passwords must be 6 characters or longer" do
    credential = users(:rob).credentials.new(type: "PasswordCredential", password: "12345")
    refute credential.valid?

    credential.password += "6"
    assert credential.valid?
  end

  test "it can validate a password" do
    assert credentials(:keith_password).authenticate("secret")
  end
end
