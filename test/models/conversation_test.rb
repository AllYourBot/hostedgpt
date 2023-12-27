require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, conversations(:greeting).user
  end

  test "has an associated assistant" do
    assert_instance_of Assistant, conversations(:greeting).assistant
  end

  test "has associated messages" do
    assert_instance_of Message, conversations(:greeting).messages.first
  end

  test "has associated runs" do
    assert_instance_of Run, conversations(:greeting).runs.first
  end

  test "has associated steps" do
    assert_instance_of Step, conversations(:greeting).steps.first
  end

  test "simple create works" do
    assert_nothing_raised do
      Conversation.create!(
        user: users(:keith),
        assistant: assistants(:samantha)
      )
    end
  end

  test "associations are deleted upon destroy" do
    assert_difference "Message.count", -4 do
      assert_difference "Run.count", -2 do
        assert_difference "Step.count", -2 do
          conversations(:greeting).destroy
        end
      end
    end
  end
end
