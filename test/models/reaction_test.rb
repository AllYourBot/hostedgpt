require "test_helper"

class ReactionTest < ActiveSupport::TestCase
  test "belongs to a user and a reactable conversation" do
    reaction = Reaction.create!(user: users(:keith), reactable: conversations(:greeting), emoji: "👍")

    assert_equal users(:keith), reaction.user
    assert_equal conversations(:greeting), reaction.reactable
    assert_equal "👍", reaction.emoji
  end

  test "belongs to a user and a reactable message" do
    reaction = Reaction.create!(user: users(:keith), reactable: messages(:hear_me), emoji: "❤️")

    assert_equal users(:keith), reaction.user
    assert_equal messages(:hear_me), reaction.reactable
  end

  test "rejects a duplicate reaction for the same user, target, and emoji" do
    Reaction.create!(user: users(:keith), reactable: conversations(:greeting), emoji: "👍")

    dup = Reaction.new(user: users(:keith), reactable: conversations(:greeting), emoji: "👍")

    assert_not dup.valid?
  end

  test "the same target accepts different emoji from the same user" do
    Reaction.create!(user: users(:keith), reactable: conversations(:greeting), emoji: "👍")

    assert_nothing_raised do
      Reaction.create!(user: users(:keith), reactable: conversations(:greeting), emoji: "🎉")
    end
  end

  test "the same target and emoji can be reacted by different users" do
    Reaction.create!(user: users(:keith), reactable: conversations(:greeting), emoji: "👍")

    assert_nothing_raised do
      Reaction.create!(user: users(:rob), reactable: conversations(:greeting), emoji: "👍")
    end
  end

  test "rejects a blank emoji" do
    reaction = Reaction.new(user: users(:keith), reactable: conversations(:greeting), emoji: "")

    assert_not reaction.valid?
  end

  test "destroying the conversation destroys its reactions" do
    conversation = conversations(:greeting)
    Reaction.create!(user: users(:keith), reactable: conversation, emoji: "👍")

    assert_difference "Reaction.count", -1 do
      conversation.destroy
    end
  end

  test "destroying the message destroys its reactions" do
    message = messages(:hear_me)
    Reaction.create!(user: users(:keith), reactable: message, emoji: "👍")

    assert_difference "Reaction.count", -1 do
      message.destroy
    end
  end
end
