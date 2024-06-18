require "test_helper"

class GmailCredentialTest < ActiveSupport::TestCase
  # See credential_test for tests in common to all credentials

  test "confirm STI is working" do
    assert_instance_of GmailCredential, credentials(:keith_gmail)
  end

  test "confirm that one of the GoogleApp included changes is working" do
    assert_equal credentials(:keith_gmail).external_id, credentials(:keith_gmail).oauth_id
  end
end
