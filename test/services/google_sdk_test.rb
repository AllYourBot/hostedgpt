require "test_helper"

class GoogleSDKTest < ActiveSupport::TestCase
  class FakeGoogleError < StandardError
    attr_reader :status, :body

    def initialize(status: nil, body: nil)
      @status = status
      @body = body
      super("fake Google OAuth error")
    end
  end

  setup do
    @user = users(:keith)
  end

  test "prune_revoked_credentials! reauthenticates every Gmail and Google Tasks credential, and nothing else" do
    seen = []
    GoogleSDK.stub :reauthenticate_credential, ->(credential) { seen << credential; true } do
      GoogleSDK.prune_revoked_credentials!(@user)
    end

    assert_equal [ credentials(:keith_gmail), credentials(:keith_google_tasks) ].sort_by(&:id), seen.sort_by(&:id)
  end

  test "reauthenticate_credential destroys the credential when Google reports the refresh token was revoked" do
    credential = credentials(:keith_gmail)
    error = FakeGoogleError.new(status: 400, body: { "error_description" => "Token has been expired or revoked." })
    stub_post_request(raises: error) do
      refute GoogleSDK.reauthenticate_credential(credential)
    end

    refute Credential.exists?(credential.id)
  end

  test "reauthenticate_credential does not destroy the credential for an unrelated error" do
    credential = credentials(:keith_gmail)
    stub_post_request(raises: FakeGoogleError.new(status: 500, body: nil)) do
      refute GoogleSDK.reauthenticate_credential(credential)
    end

    assert Credential.exists?(credential.id)
  end

  test "reauthenticate_credential does not raise or destroy the credential when the error has no status (e.g. a network failure)" do
    credential = credentials(:keith_gmail)
    stub_post_request(raises: FakeGoogleError.new) do
      refute GoogleSDK.reauthenticate_credential(credential)
    end

    assert Credential.exists?(credential.id)
  end

  private

  def stub_post_request(raises:, &block)
    fake_request = Object.new
    fake_request.define_singleton_method(:www_content) { fake_request }
    fake_request.define_singleton_method(:param) { |*| raise raises }

    SDK::Post.stub :new, fake_request, &block
  end
end
