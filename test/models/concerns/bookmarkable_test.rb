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
  end

  test "unbookmarking an unbookmarked conversation is a no-op" do
    conversation = conversations(:greeting)

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
    assert_not_includes Conversation.bookmarked_for(@keith).map(&:id), rob_conversation.id

    assert_empty Conversation.bookmarked_for(@rob)
  end

  test "toggling a bookmark never touches conversation recency" do
    conversation = conversations(:greeting)

    assert_no_changes -> { conversation.reload.updated_at } do
      conversation.bookmark!(@keith)
      conversation.unbookmark!(@keith)
    end
  end

  test "a message can be bookmarked and unbookmarked the same way" do
    message = messages(:hear_me)

    assert_not message.bookmarked?(@keith)

    message.bookmark!(@keith)

    assert message.bookmarked?(@keith)
    assert_includes Message.bookmarked_for(@keith).map(&:id), message.id

    message.unbookmark!(@keith)

    assert_not message.bookmarked?(@keith)
  end

  test "destroying a message destroys its bookmarks" do
    message = messages(:hear_me)
    message.bookmark!(@keith)

    assert_difference "Bookmark.count", -1 do
      message.destroy
    end
  end

  test "destroying an assistant destroys its messages' bookmarks" do
    message = messages(:yes_i_do)
    message.bookmark!(@keith)

    assert_difference "Bookmark.count", -1 do
      assistants(:samantha).destroy
    end
  end

  test "a RecordNotUnique race on concurrent inserts resolves to the existing row" do
    conversation = conversations(:greeting)
    row = conversation.bookmark!(@keith)

    # Simulate losing the create race: the association's find misses, then the insert
    # hits the composite unique index, and the rescue must recover the existing row.
    raced = false
    original_bookmarks = conversation.method(:bookmarks)
    conversation.define_singleton_method(:bookmarks) do
      proxy = original_bookmarks.call
      unless raced
        raced = true
        proxy.singleton_class.define_method(:find_or_create_by!) { |*| raise ActiveRecord::RecordNotUnique }
      end
      proxy
    end

    assert_equal row.id, conversation.bookmark!(@keith).id
    assert_equal 1, conversation.bookmarks.count
  end
end
