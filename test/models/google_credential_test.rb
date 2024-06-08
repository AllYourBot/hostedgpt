require "test_helper"

class GoogleCredentialTest < ActiveSupport::TestCase
  # See credential_test for tests in common to all credentials

  setup do
    @user = users(:rob)
  end

  test "simple create works" do
    credential = @user.credentials.new(details)
    assert credential.save
    assert credential.is_a?(GoogleCredential)
  end

  test "requires an oauth_id, oauth_token, oauth_refresh_token, oauth_email to create" do
    refute @user.credentials.new(details.except(:oauth_id)).valid?
    refute @user.credentials.new(details.except(:oauth_token)).valid?
    refute @user.credentials.new(details.except(:oauth_refresh_token)).valid?
    refute @user.credentials.new(details.except(:oauth_email)).valid?
  end

  test "oauth_email must be unique" do
    rob_cred = @user.credentials.new(details)
    assert rob_cred.save

    keith_cred = users(:keith).credentials.new(details.merge(oauth_id: "123uniq"))
    refute keith_cred.save
    assert_equal ["has already been taken"], keith_cred.errors[:oauth_email]
  end

  test "oauth_id must be unique" do
    rob_cred = @user.credentials.new(details)
    assert rob_cred.save

    keith_cred = users(:keith).credentials.new(details.merge(oauth_email: "uniq123@email.com"))
    refute keith_cred.save
    assert_equal ["has already been taken"], keith_cred.errors[:oauth_id]
  end

  private

  def details
    {
      type: "GoogleCredential",
      oauth_id: "123",
      oauth_token: "abc-123",
      oauth_refresh_token: "def-456",
      oauth_email: "other-rob-email@gmail.com",
      properties: {}
    }
  end
end
