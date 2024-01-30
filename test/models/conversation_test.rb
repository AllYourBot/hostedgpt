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

  test "conversations are destroyed when user is destroyed" do
    conversation = conversations(:greeting)
    conversation.user.destroy
    assert_raises ActiveRecord::RecordNotFound do
      conversation.reload
    end
  end

  test "#grouped_by_increasing_time_interval_for_user" do
    Timecop.freeze do
      user = User.create!(password: "secret")

      # Create 3 conversations in each of these intervals
      [
        1.week.ago,
        1.month.ago,
        1.year.ago
      ].each do |timestamp|
        3.times do
          Conversation.create!(
            user: user,
            assistant: assistants(:samantha),
            created_at: timestamp,
            updated_at: timestamp
          )
        end
      end

      grouped_conversations = Conversation.grouped_by_increasing_time_interval_for_user(user)

      # Creating a user automatically creates a conversation
      assert_equal 1, grouped_conversations["Today"].count
      assert_equal 3, grouped_conversations["This Week"].count
      assert_equal 3, grouped_conversations["This Month"].count
      assert_equal 3, grouped_conversations["Older"].count
    end
  end
end