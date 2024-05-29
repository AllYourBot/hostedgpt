require "test_helper"

class GmailCredentialTest < ActiveSupport::TestCase
  test "refresh_token convenience method works" do
    assert_equal credentials(:keith_gmail).properties[:refresh_token], credentials(:keith_gmail).refresh_token
  end

  test "has one associcated active_credential" do
    assert_equal authentications(:keith_gmail_active), credentials(:keith_gmail).active_authentication
  end
end
