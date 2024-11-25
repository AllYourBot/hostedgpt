require "test_helper"

class MicrosoftGraphCredentialTest < ActiveSupport::TestCase
  # See credential_test for tests in common to all credentials

  test "confirm STI is working" do
    assert_instance_of MicrosoftGraphCredential, credentials(:keith_microsoft_graph)
  end

  test "confirm that one of the MicrosoftGraphApp included changes is working" do
    assert_equal credentials(:keith_microsoft_graph).external_id, credentials(:keith_microsoft_graph).oauth_id
  end

  test "token not expired so not renewed" do
    credential = credentials(:keith_microsoft_graph)
    refute credential.expired?
    token = credential.token
    assert token
    credential.reload
    assert_equal token, credential.token
  end

  test "token expired" do
    credential = credentials(:keith_microsoft_graph)
    credential.update(properties: { expires_at: 1.minute.ago.to_i })
    assert credential.expired?
  end
end
