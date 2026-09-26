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

  test "pin claims the top slot, unpin leaves it, re-pin re-claims the top" do
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
end
