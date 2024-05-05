require "test_helper"

class Message::CancellableTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:greeting)
    @previous_id = @conversation.latest_message_for_version(:latest).id
  end

  test "cancelled_by" do
    assert_equal users(:keith), messages(:dont_know_day).cancelled_by
  end

  test "when a message is cancelled this user.last_cancelled_message gets set" do
    Current.user = users(:keith)

    assert_changes "messages(:im_a_bot).cancelled_at", from: nil do
      assert_changes "users(:keith).last_cancelled_message", to: messages(:im_a_bot) do
        messages(:im_a_bot).cancelled!
      end
    end
  end

  test "creating a new message on a conversation updates the conversation.last_assistant_message" do
    assert_changes "@conversation.last_assistant_message_id", from: @previous_id do
      assert_difference "@conversation.messages.count", 2 do
        @conversation.messages.create!(
          assistant: @conversation.assistant,
          content_text: "A new message"
        )
      end
    end
    id = @conversation.latest_message_for_version(:latest).reload.id
    assert_equal id, @conversation.last_assistant_message_id
  end
end
