require "test_helper"

class ConversationsPublicTest < ActionDispatch::IntegrationTest
  setup do
    @conversation = conversations(:greeting)
    @conversation.ensure_share_token!
  end

  test "public_show displays conversation without authentication" do
    get public_conversation_path(@conversation.share_token)

    assert_response :success
    assert_select "h2", text: @conversation.title
  end

  test "public_show shows messages" do
    get public_conversation_path(@conversation.share_token)

    assert_response :success
    # Check that at least some message content is displayed
    assert_match "Keith Schacht", response.body
    assert_match "Samantha", response.body
  end

  test "public_show returns 404 for invalid token" do
    get public_conversation_path("invalid-token")
    assert_response :not_found
  end

  test "public_show does not require authentication" do
    # Ensure we're not logged in
    delete logout_path if defined?(logout_path)

    get public_conversation_path(@conversation.share_token)
    assert_response :success
  end
end