require "test_helper"

class PinTest < ActiveSupport::TestCase
  test "belongs to a user and a pinnable conversation" do
    pin = Pin.create!(user: users(:keith), pinnable: conversations(:greeting))

    assert_equal users(:keith), pin.user
    assert_equal conversations(:greeting), pin.pinnable
  end

  test "rejects a duplicate pin for the same user and target" do
    Pin.create!(user: users(:keith), pinnable: conversations(:greeting))

    dup = Pin.new(user: users(:keith), pinnable: conversations(:greeting))

    assert_not dup.valid?
  end

  test "the same conversation can be pinned by different users" do
    Pin.create!(user: users(:keith), pinnable: conversations(:greeting))

    assert_nothing_raised do
      Pin.create!(user: users(:rob), pinnable: conversations(:greeting))
    end
  end

  test "destroying the conversation destroys its pins" do
    conversation = conversations(:greeting)
    Pin.create!(user: users(:keith), pinnable: conversation)

    assert_difference "Pin.count", -1 do
      conversation.destroy
    end
  end
end
