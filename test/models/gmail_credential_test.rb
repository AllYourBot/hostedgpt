require "test_helper"

class GmailCredentialTest < ActiveSupport::TestCase
  test "refresh_token convenience method works" do
    assert credentials(:keith_gmail).properties[:refresh_token], credentials(:keith_gmail).refresh_token
  end
end
