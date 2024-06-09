require "test_helper"

class PasswordCredentialTest < ActiveSupport::TestCase
  # See credential_test for tests in common to all credentials

  setup do
    @user = users(:rob)
  end

  test "simple create woroks" do
    minimum_credential = @user.credentials.new(details)
    assert minimum_credential.save
  end

  test "password is required" do
    minimum_credential = @user.credentials.new(details)
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
    credential = @user.credentials.new(details.merge(password: "12345"))
    refute credential.valid?

    credential.password += "6"
    assert credential.valid?
  end

  test "it can validate a password" do
    assert credentials(:keith_password).authenticate("secret")
  end

  def details
    {
      type: "PasswordCredential",
      password: "password"
    }
  end
end
