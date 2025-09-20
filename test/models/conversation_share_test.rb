require "test_helper"

class ConversationShareTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:greeting)
  end

  test "generates share token on create" do
    new_conversation = Conversation.create!(
      user: users(:keith),
      assistant: assistants(:samantha)
    )
    assert_not_nil new_conversation.share_token
    assert new_conversation.share_token.length > 20
  end

  test "ensure_share_token! generates token for existing conversations" do
    @conversation.update_column(:share_token, nil)
    assert_nil @conversation.share_token

    @conversation.ensure_share_token!
    assert_not_nil @conversation.share_token
    assert @conversation.share_token.length > 20
  end

  test "generate_shareable_url returns correct URL" do
    request = OpenStruct.new(host_with_port: "localhost:3000")
    @conversation.ensure_share_token!

    url = @conversation.generate_shareable_url(request)
    assert_includes url, "localhost:3000"
    assert_includes url, "/share/"
    assert_includes url, @conversation.share_token
  end

  test "share tokens are unique" do
    conversations = 5.times.map do
      Conversation.create!(
        user: users(:keith),
        assistant: assistants(:samantha)
      )
    end

    tokens = conversations.map(&:share_token)
    assert_equal tokens.uniq.length, tokens.length
  end
end