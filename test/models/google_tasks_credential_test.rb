require "test_helper"

class GoogleTasksCredentialTest < ActiveSupport::TestCase
  # See credential_test for tests in common to all credentials

  test "confirm STI is working" do
    assert_instance_of GoogleTasksCredential, credentials(:keith_google_tasks)
  end

  test "confirm that one of the GoogleApp included changes is working" do
    assert_equal credentials(:keith_google_tasks).external_id, credentials(:keith_google_tasks).oauth_id
  end
end
