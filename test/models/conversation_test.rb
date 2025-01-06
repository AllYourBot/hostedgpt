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

  test "has associated last_assistant_message but can also be nil" do
    c = Conversation.create!(user: users(:keith), assistant: assistants(:samantha))
    assert_nil c.last_assistant_message
    assert_instance_of Message, conversations(:greeting).last_assistant_message
  end

  test "simple create works" do
    assert_nothing_raised do
      Conversation.create!(
        user: users(:keith),
        assistant: assistants(:samantha)
      )
    end
  end

  test "Conversation should not be created with duplicate external ids" do
    Conversation.create!(
      user: users(:keith),
      assistant: assistants(:samantha),
      external_id: "dup1"
    )

    assert_raise ActiveRecord::RecordNotUnique do
      Conversation.create!(
        user: users(:keith),
        assistant: assistants(:mandela_gpt4),
        external_id: "dup1"
      )
    end
  end

  test "associations are deleted upon destroy" do
    conversation = conversations(:greeting)
    message_count = conversation.messages.count * -1
    run_count = conversation.runs.count * -1
    step_count = conversation.steps.count * -1

    assert_difference "Message.count", message_count do
      assert_difference "Run.count", run_count do
        assert_difference "Step.count", step_count do
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

  test "the title of a conversation is automatically set when the second message is created by the job" do
    assistants(:samantha).language_model.update!(supports_tools: false)

    perform_enqueued_jobs do
      TestClient::OpenAI.stub :text, "{\"topic\":\"Hear me\"}" do
        conversation = users(:keith).conversations.create!(assistant: assistants(:samantha))
        assert_nil conversation.title

        conversation.messages.create!(assistant: conversation.assistant, role: :user, content_text: "Can you hear me?")

        latest_message = conversation.latest_message_for_version(:latest)
        assert latest_message.assistant?

        GetNextAIMessageJob.perform_now(users(:keith).id, latest_message.id, assistants(:samantha).id)

        assert_equal "Hear me", conversation.reload.title
      end
    end
  end

  test "#grouped_by_increasing_time_interval_for_user" do
    Timecop.freeze(Time.current.beginning_of_day + 12.hours) do
      user = User.create!(first_name: "John", last_name: "Doe")

      # Create 3 conversations in each of these intervals
      [
        Time.zone.today,
        1.week.ago.in_time_zone,
        1.month.ago.in_time_zone,
        1.year.ago.in_time_zone
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
      assert_equal 3, grouped_conversations["Today"].count
      assert_equal 3, grouped_conversations["This Week"].count
      assert_equal 3, grouped_conversations["This Month"].count
      assert_equal 3, grouped_conversations["Older"].count
    end
  end

  test "#grouped_by_increasing_time_interval_for_user with a query returning a single conversation title" do
    user = users(:keith)
    query = "Ruby"

    grouped_conversations = Conversation.grouped_by_increasing_time_interval_for_user(user, query).values.flatten

    assert_equal 1, grouped_conversations.count
    assert_equal conversations(:ruby_version), grouped_conversations.first, "Should have returned this conversation based on title"
  end

  test "#grouped_by_increasing_time_interval_for_user with a query returning a single conversation message" do
    user = users(:keith)
    query = "alive"

    grouped_conversations = Conversation.grouped_by_increasing_time_interval_for_user(user, query).values.flatten

    assert_equal 1, grouped_conversations.count
    assert_equal conversations(:greeting), grouped_conversations.first, "Should have returned this conversation based on message content"
  end

  test "#grouped_by_increasing_time_interval_for_user with a query returning matching conversation titles and a message" do
    user = users(:keith)
    query = "test"

    grouped_conversations = Conversation.grouped_by_increasing_time_interval_for_user(user, query).values.flatten

    assert_equal 3, grouped_conversations.count
    assert_equal [
      conversations(:attachment).id, # matches title
      conversations(:attachments).id, # matches title
      conversations(:ruby_version).id # matches "latest" in messages
    ].sort, grouped_conversations.map(&:id).sort, "Should have returned these conversations based on title and message content"
  end
end
