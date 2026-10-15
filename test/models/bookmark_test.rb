require "test_helper"

class BookmarkTest < ActiveSupport::TestCase
  test "belongs to a user and a bookmarkable conversation" do
    bookmark = Bookmark.create!(user: users(:keith), bookmarkable: conversations(:greeting))

    assert_equal users(:keith), bookmark.user
    assert_equal conversations(:greeting), bookmark.bookmarkable
  end

  test "rejects a duplicate bookmark for the same user and target" do
    Bookmark.create!(user: users(:keith), bookmarkable: conversations(:greeting))

    dup = Bookmark.new(user: users(:keith), bookmarkable: conversations(:greeting))

    assert_not dup.valid?
  end

  test "the same conversation can be bookmarked by different users" do
    Bookmark.create!(user: users(:keith), bookmarkable: conversations(:greeting))

    assert_nothing_raised do
      Bookmark.create!(user: users(:rob), bookmarkable: conversations(:greeting))
    end
  end

  test "destroying the conversation destroys its bookmarks" do
    conversation = conversations(:greeting)
    Bookmark.create!(user: users(:keith), bookmarkable: conversation)

    assert_difference "Bookmark.count", -1 do
      conversation.destroy
    end
  end
end
