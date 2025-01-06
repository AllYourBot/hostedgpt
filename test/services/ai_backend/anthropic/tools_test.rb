require "test_helper"

class AIBackend::Anthropic::ToolsTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:attachments)
    @anthropic = AIBackend::Anthropic.new(users(:keith),
      assistants(:keith_claude3),
      @conversation,
      @conversation.latest_message_for_version(:latest)
    )
    @test_client = TestClient::Anthropic.new(access_token: "abc")
  end

end
