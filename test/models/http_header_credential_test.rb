require "test_helper"

class HttpHeaderCredentialTest < ActiveSupport::TestCase
  # See credential_test for tests in common to all credentials

  setup do
    @user = users(:rob)
  end

  test "simple create works" do
    credential = @user.credentials.new(details)
    assert credential.save
    assert credential.is_a?(HttpHeaderCredential)
  end

  test "requires an auth_uid to create" do
    refute @user.credentials.new(details.except(:auth_uid)).valid?
  end

  test "auth_uid must be unique" do
    rob_cred = users(:rob).credentials.new(details)
    assert rob_cred.save

    keith_cred = users(:keith).credentials.new(details)
    refute keith_cred.save
    assert_equal ["has already been taken"], keith_cred.errors[:auth_uid]
  end

  private

  def details
    {
      type: "HttpHeaderCredential",
      auth_uid: "abc123",
    }
  end
end
