require "test_helper"

class Message::CancellableTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:greeting)
    @previous_id = @conversation.latest_message.id
    redis.set("conversation-#{@conversation.id}-latest_message-id", @previous_id)
  end

  teardown do
    redis.set("conversation-#{@conversation.id}-latest_message-id", @previous_id) # cleanup
  end

  test "when a message is cancelled the redis key gets set" do
    redis.set("message-cancelled-id", nil)

    assert_changes "messages(:im_a_bot).cancelled_at", from: nil do
      assert_changes "redis.get('message-cancelled-id')&.to_i", to: messages(:im_a_bot).id do
        messages(:im_a_bot).cancelled!
      end
    end

    redis.set("message-cancelled-id", nil)
  end

  test "creating a new message on a conversation updates the redis key for that conversation" do
    assert_changes "redis.get('conversation-#{@conversation.id}-latest_message-id')&.to_i", from: @previous_id do
      assert_difference "@conversation.messages.count", 2 do
        @conversation.messages.create!(
          assistant: @conversation.assistant,
          content_text: "A new message"
        )
      end
    end

    assert_equal @conversation.latest_message.reload.id, redis.get("conversation-#{@conversation.id}-latest_message-id")&.to_i
  end

  private

  def redis
    RedisConnection.client
  end
end
