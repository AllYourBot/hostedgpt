require "test_helper"

class BookmarkableTest < ActiveSupport::TestCase
  setup do
    @keith = users(:keith)
    @rob = users(:rob)
  end

  test "bookmark moves a conversation into bookmarked_for and unbookmark removes it" do
    conversation = conversations(:greeting)

    assert_not conversation.bookmarked?(@keith)
    assert_not_includes Conversation.bookmarked_for(@keith).map(&:id), conversation.id

    conversation.bookmark!(@keith)

    assert conversation.bookmarked?(@keith)
    assert_includes Conversation.bookmarked_for(@keith).map(&:id), conversation.id
    assert_includes @keith.conversations.bookmarked_for(@keith).map(&:id), conversation.id

    conversation.unbookmark!(@keith)

    assert_not conversation.bookmarked?(@keith)
    assert_not_includes Conversation.bookmarked_for(@keith).map(&:id), conversation.id
  end

  test "double bookmark is idempotent" do
    conversation = conversations(:greeting)
    conversation.bookmark!(@keith)

    assert_no_difference "Bookmark.count" do
      conversation.bookmark!(@keith)
    end

    assert conversation.bookmarked?(@keith)
    assert_includes Conversation.bookmarked_for(@keith).map(&:id), conversation.id
  end

  test "unbookmarking an unbookmarked conversation is a no-op" do
    conversation = conversations(:greeting)

    assert_not conversation.bookmarked?(@keith)

    assert_no_difference "Bookmark.count" do
      conversation.unbookmark!(@keith)
    end

    assert_not conversation.bookmarked?(@keith)
  end

  test "one user's bookmarks never leak into another user's scope" do
    keith_conversation = conversations(:greeting)
    rob_conversation = conversations(:debugging)
    keith_conversation.bookmark!(@keith)

    assert_includes Conversation.bookmarked_for(@keith).map(&:id), keith_conversation.id

    assert_empty Conversation.bookmarked_for(@rob)
    assert_not_includes Conversation.bookmarked_for(@rob).map(&:id), keith_conversation.id
    assert_not_includes Conversation.bookmarked_for(@keith).map(&:id), rob_conversation.id
  end

  test "toggling a bookmark never touches sidebar order" do
    before = @keith.conversations.ordered.pluck(:id, :position)
    conversation = conversations(:greeting)

    conversation.bookmark!(@keith)

    assert_equal before, @keith.conversations.ordered.pluck(:id, :position)

    conversation.unbookmark!(@keith)

    assert_equal before, @keith.conversations.ordered.pluck(:id, :position)
  end
end
