require "test_helper"

class PinsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @conversation = conversations(:greeting)
    login_as @conversation.user
  end

  test "create pins the conversation" do
    post conversation_pin_url(@conversation)

    assert_redirected_to root_url
    assert @conversation.reload.pinned?
  end

  test "create goes back to the page the user was on" do
    post conversation_pin_url(@conversation), headers: { "Referer" => conversation_messages_url(@conversation) }

    assert_redirected_to conversation_messages_url(@conversation)
  end

  test "destroy unpins the conversation" do
    @conversation.pin!

    delete conversation_pin_url(@conversation)

    assert_redirected_to root_url
    assert_not @conversation.reload.pinned?
  end

  test "create leaves another user's conversation alone" do
    rob_conversation = conversations(:debugging)

    post conversation_pin_url(rob_conversation)

    assert_response :not_found
    assert_not rob_conversation.reload.pinned?
  end

  test "destroy leaves another user's conversation alone" do
    rob_conversation = conversations(:debugging)
    rob_conversation.pin!

    delete conversation_pin_url(rob_conversation)

    assert_response :not_found
    assert rob_conversation.reload.pinned?
  end

  test "requires a login" do
    get logout_path

    post conversation_pin_url(@conversation)

    assert_redirected_to login_url
    assert_not @conversation.reload.pinned?
  end
end
