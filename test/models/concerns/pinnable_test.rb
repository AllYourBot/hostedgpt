require "test_helper"

class PinnableTest < ActiveSupport::TestCase
  setup do
    @keith = users(:keith)
    @rob = users(:rob)
  end

  test "pin moves a conversation into pinned_for and unpin moves it back to unpinned_for" do
    conversation = conversations(:greeting)

    assert_not conversation.pinned?(@keith)
    assert_includes Conversation.unpinned_for(@keith).map(&:id), conversation.id

    conversation.pin!(@keith)

    assert conversation.pinned?(@keith)
    assert_includes Conversation.pinned_for(@keith).map(&:id), conversation.id
    assert_includes @keith.conversations.pinned_for(@keith).map(&:id), conversation.id
    assert_not_includes Conversation.unpinned_for(@keith).map(&:id), conversation.id

    conversation.unpin!(@keith)

    assert_not conversation.pinned?(@keith)
    assert_not_includes Conversation.pinned_for(@keith).map(&:id), conversation.id
    assert_includes Conversation.unpinned_for(@keith).map(&:id), conversation.id
  end

  test "double pin is idempotent" do
    conversation = conversations(:greeting)
    conversation.pin!(@keith)

    assert_no_difference "Pin.count" do
      conversation.pin!(@keith)
    end

    assert conversation.pinned?(@keith)
    assert_includes Conversation.pinned_for(@keith).map(&:id), conversation.id
  end

  test "unpinning an unpinned conversation is a no-op" do
    conversation = conversations(:greeting)

    assert_not conversation.pinned?(@keith)

    assert_no_difference "Pin.count" do
      conversation.unpin!(@keith)
    end

    assert_not conversation.pinned?(@keith)
  end

  test "one user's pins never leak into another user's scopes" do
    keith_conversation = conversations(:greeting)
    rob_conversation = conversations(:debugging)
    keith_conversation.pin!(@keith)

    assert_includes Conversation.pinned_for(@keith).map(&:id), keith_conversation.id
    assert_not_includes Conversation.unpinned_for(@keith).map(&:id), keith_conversation.id

    assert_empty Conversation.pinned_for(@rob)
    assert_not_includes Conversation.pinned_for(@rob).map(&:id), keith_conversation.id
    assert_includes Conversation.unpinned_for(@rob).map(&:id), rob_conversation.id
  end

  test "pin claims the top slot, unpin leaves it, re-pin after unpin re-claims the top" do
    Conversation.reposition(@keith, @keith.conversations.ordered.pluck(:id)) # normalize to 0..n-1
    conversation = conversations(:greeting)
    other = conversations(:attachment)

    min_before = @keith.conversations.minimum(:position)
    conversation.pin!(@keith)

    assert_equal min_before - 1, conversation.reload.position

    conversation.unpin!(@keith)

    assert_equal min_before - 1, conversation.reload.position

    other.pin!(@keith)
    min_before_repin = @keith.conversations.minimum(:position)
    conversation.pin!(@keith)

    assert_equal min_before_repin - 1, conversation.reload.position
    assert_equal conversation.id, Conversation.pinned_for(@keith).first.id
  end

  test "double pin while pinned is fully idempotent and never drifts the minimum" do
    Conversation.reposition(@keith, @keith.conversations.ordered.pluck(:id)) # normalize to 0..n-1
    conversation = conversations(:greeting)

    conversation.pin!(@keith)
    position_after_first_pin = conversation.reload.position
    min_after_first_pin = @keith.conversations.minimum(:position)

    assert_no_difference("Pin.count") { conversation.pin!(@keith) }

    assert_equal position_after_first_pin, conversation.reload.position
    assert_equal min_after_first_pin, @keith.conversations.minimum(:position)
  end

  test "pin and unpin toggle membership on a message with no hand order" do
    message = messages(:hear_me)

    assert_not message.pinned?(@keith)
    assert_not_includes Message.pinned_for(@keith).map(&:id), message.id

    message.pin!(@keith)

    assert message.pinned?(@keith)
    assert_includes Message.pinned_for(@keith).map(&:id), message.id
    assert_not_includes Message.unpinned_for(@keith).map(&:id), message.id

    message.unpin!(@keith)

    assert_not message.pinned?(@keith)
    assert_not_includes Message.pinned_for(@keith).map(&:id), message.id
    assert_includes Message.unpinned_for(@keith).map(&:id), message.id
  end

  test "double pin on a message is idempotent" do
    message = messages(:hear_me)
    message.pin!(@keith)

    assert_no_difference "Pin.count" do
      message.pin!(@keith)
    end

    assert message.pinned?(@keith)
    assert_includes Message.pinned_for(@keith).map(&:id), message.id
  end

  test "unpinning an unpinned message is a no-op" do
    message = messages(:hear_me)

    assert_not message.pinned?(@keith)

    assert_no_difference "Pin.count" do
      message.unpin!(@keith)
    end

    assert_not message.pinned?(@keith)
  end

  test "one user's message pins never leak into another user's scopes" do
    message = messages(:hear_me)
    message.pin!(@keith)

    assert_includes Message.pinned_for(@keith).map(&:id), message.id
    assert_not_includes Message.unpinned_for(@keith).map(&:id), message.id

    assert_empty Message.pinned_for(@rob)
    assert_not_includes Message.pinned_for(@rob).map(&:id), message.id
    assert_includes Message.unpinned_for(@rob).map(&:id), messages(:filter_map).id
  end

  test "pinning a message leaves conversation positions and pin order untouched" do
    positions_before = @keith.conversations.order(:id).pluck(:id, :position)
    pinned_before = Conversation.pinned_for(@keith).pluck(:id)

    messages(:hear_me).pin!(@keith)

    assert_equal positions_before, @keith.conversations.order(:id).pluck(:id, :position)
    assert_equal pinned_before, Conversation.pinned_for(@keith).pluck(:id)
  end
end
