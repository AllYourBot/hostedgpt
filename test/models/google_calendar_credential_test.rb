require "test_helper"

class GoogleCalendarCredentialTest < ActiveSupport::TestCase
  # See credential_test for tests in common to all credentials

  test "confirm STI is working" do
    assert_instance_of GoogleCalendarCredential, credentials(:keith_google_calendar)
  end

  test "confirm that one of the GoogleApp included changes is working" do
    assert_equal credentials(:keith_google_calendar).external_id, credentials(:keith_google_calendar).oauth_id
  end
end
