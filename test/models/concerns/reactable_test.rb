require "test_helper"

class ReactableTest < ActiveSupport::TestCase
  setup do
    @keith = users(:keith)
    @rob = users(:rob)
  end

  test "react and unreact toggle counts on a conversation" do
    conversation = conversations(:greeting)

    assert_equal({}, conversation.reaction_counts)
    assert_not conversation.user_reacted?("👍", @keith)

    conversation.react!("👍", @keith)

    assert conversation.user_reacted?("👍", @keith)
    assert_equal({ "👍" => 1 }, conversation.reaction_counts)

    conversation.unreact!("👍", @keith)

    assert_not conversation.user_reacted?("👍", @keith)
    assert_equal({}, conversation.reaction_counts)
  end

  test "react and unreact toggle counts on a message" do
    message = messages(:hear_me)

    assert_equal({}, message.reaction_counts)

    message.react!("❤️", @keith)

    assert message.user_reacted?("❤️", @keith)
    assert_equal({ "❤️" => 1 }, message.reaction_counts)

    message.unreact!("❤️", @keith)

    assert_not message.user_reacted?("❤️", @keith)
    assert_equal({}, message.reaction_counts)
  end

  test "counts group by emoji across users" do
    conversation = conversations(:greeting)
    conversation.react!("👍", @keith)
    conversation.react!("👍", @rob)
    conversation.react!("🎉", @keith)

    assert_equal({ "👍" => 2, "🎉" => 1 }, conversation.reaction_counts)
  end

  test "duplicate react is idempotent" do
    conversation = conversations(:greeting)
    conversation.react!("👍", @keith)

    assert_no_difference "Reaction.count" do
      conversation.react!("👍", @keith)
    end

    assert conversation.user_reacted?("👍", @keith)
    assert_equal({ "👍" => 1 }, conversation.reaction_counts)
  end

  test "unreacting a clear emoji is a no-op" do
    conversation = conversations(:greeting)

    assert_no_difference "Reaction.count" do
      conversation.unreact!("👍", @keith)
    end

    assert_not conversation.user_reacted?("👍", @keith)
  end

  test "reacting with a blank emoji is rejected" do
    conversation = conversations(:greeting)

    assert_raises ActiveRecord::RecordInvalid do
      conversation.react!("", @keith)
    end

    assert_raises ActiveRecord::RecordInvalid do
      conversation.react!(nil, @keith)
    end
  end

  test "reacted_for scopes membership per user" do
    conversation = conversations(:greeting)

    assert_not_includes Conversation.reacted_for(@keith).map(&:id), conversation.id

    conversation.react!("👍", @keith)

    assert_includes Conversation.reacted_for(@keith).map(&:id), conversation.id
    assert_includes @keith.conversations.reacted_for(@keith).map(&:id), conversation.id

    conversation.unreact!("👍", @keith)

    assert_not_includes Conversation.reacted_for(@keith).map(&:id), conversation.id
  end

  test "one user's reactions never leak into another user's scope" do
    keith_conversation = conversations(:greeting)
    rob_conversation = conversations(:debugging)
    keith_conversation.react!("👍", @keith)

    assert_includes Conversation.reacted_for(@keith).map(&:id), keith_conversation.id

    assert_empty Conversation.reacted_for(@rob)
    assert_not_includes Conversation.reacted_for(@rob).map(&:id), keith_conversation.id
    assert_not_includes Conversation.reacted_for(@keith).map(&:id), rob_conversation.id
  end

  test "one user's message reactions never leak to another user" do
    message = messages(:hear_me)
    message.react!("👍", @keith)

    assert message.user_reacted?("👍", @keith)
    assert_not message.user_reacted?("👍", @rob)
    assert_equal({ "👍" => 1 }, message.reaction_counts)
  end

  test "toggling a reaction never touches conversation order" do
    before = @keith.conversations.ordered.pluck(:id, :position)
    conversation = conversations(:greeting)

    conversation.react!("👍", @keith)

    assert_equal before, @keith.conversations.ordered.pluck(:id, :position)

    conversation.unreact!("👍", @keith)

    assert_equal before, @keith.conversations.ordered.pluck(:id, :position)
  end
end
