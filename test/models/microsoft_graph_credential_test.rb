require "test_helper"

class MicrosoftGraphCredentialTest < ActiveSupport::TestCase
  # See credential_test for tests in common to all credentials

  test "confirm STI is working" do
    assert_instance_of MicrosoftGraphCredential, credentials(:keith_microsoft_graph)
  end

  test "confirm that one of the MicrosoftGraphApp included changes is working" do
    assert_equal credentials(:keith_microsoft_graph).external_id, credentials(:keith_microsoft_graph).oauth_id
  end
end
