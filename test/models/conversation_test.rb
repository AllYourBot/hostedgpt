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
      TestClient::RubyLLM::Chat.stub :text, "{\"topic\":\"Hear me\"}" do
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

  test "mark_unread! and mark_read! toggle unread WITHOUT changing updated_at" do
    conversation = conversations(:greeting)
    refute conversation.unread?, "A conversation should be read by default"

    assert_no_changes -> { conversation.reload.updated_at }, "Being read should not move the conversation in the sidebar" do
      conversation.mark_unread!
      assert conversation.reload.unread?, "mark_unread! should mark it unread"

      assert conversation.mark_read!, "mark_read! should report that it changed an unread conversation"
      refute conversation.reload.unread?, "mark_read! should mark it read"
    end
  end

  test "mark_read! reports NO CHANGE for a conversation that is already read" do
    refute conversations(:greeting).mark_read!, "There was nothing to mark read"
  end

  test "is not pinned by default" do
    conversation = conversations(:greeting)

    assert_nil conversation.pin_position
    assert_not conversation.pinned?
  end

  test "#pin! pins the conversation" do
    conversation = conversations(:greeting)

    conversation.pin!

    assert conversation.reload.pinned?
  end

  test "#pin! puts the newest pin at the top of the pinned list" do
    first = conversations(:greeting)
    second = conversations(:ruby_version)

    first.pin!
    second.pin!

    assert_equal [second, first], users(:keith).conversations.pinned.to_a
  end

  test "#pin! leaves an already pinned conversation where it is" do
    first = conversations(:greeting)
    second = conversations(:ruby_version)
    first.pin!
    second.pin!

    assert_no_changes -> { first.reload.pin_position } do
      first.pin!
    end
    assert_equal [second, first], users(:keith).conversations.pinned.to_a
  end

  test "#pin! does not change updated_at" do
    conversation = conversations(:greeting)

    assert_no_changes -> { conversation.reload.updated_at } do
      conversation.pin!
    end
  end

  test "#pin! numbers each user's pins on their own" do
    rob_conversation = conversations(:debugging)
    keith_conversation = conversations(:greeting)

    rob_conversation.pin!
    keith_conversation.pin!

    assert_equal rob_conversation.reload.pin_position, keith_conversation.reload.pin_position
  end

  test "#unpin! removes the pin" do
    conversation = conversations(:greeting)
    conversation.pin!

    conversation.unpin!

    assert_nil conversation.reload.pin_position
    assert_not conversation.pinned?
  end

  test ".pinned only includes pinned conversations" do
    pinned = conversations(:greeting)
    pinned.pin!

    assert_equal [pinned], users(:keith).conversations.pinned.to_a
  end

  test "#grouped_by_increasing_time_interval_for_user includes pinned conversations by default" do
    pinned = conversations(:greeting)
    pinned.pin!

    grouped_conversations = Conversation.grouped_by_increasing_time_interval_for_user(users(:keith)).values.flatten

    assert_includes grouped_conversations, pinned
  end

  test "#grouped_by_increasing_time_interval_for_user with exclude_pinned leaves out pinned conversations" do
    pinned = conversations(:greeting)
    unpinned = conversations(:ruby_version)
    pinned.pin!

    grouped_conversations = Conversation.grouped_by_increasing_time_interval_for_user(users(:keith), exclude_pinned: true).values.flatten

    assert_not_includes grouped_conversations, pinned
    assert_includes grouped_conversations, unpinned
  end

  test "#grouped_by_increasing_time_interval_for_user with exclude_pinned and a query leaves out pinned conversations" do
    conversations(:ruby_version).pin!

    grouped_conversations = Conversation.grouped_by_increasing_time_interval_for_user(users(:keith), "Ruby", exclude_pinned: true).values.flatten

    assert_empty grouped_conversations
  end

  test ".reposition renumbers the pinned conversations to match the order of the ids it is given" do
    keith = users(:keith)
    ids = %i[greeting ruby_version attachment].map { |name| conversations(name).tap(&:pin!).id }
    assert_equal ids.reverse, keith.conversations.pinned.pluck(:id), "The newest pin starts on top"

    keith.conversations.reposition(ids.map(&:to_s)) # the ids arrive from the browser as strings

    assert_equal ids, keith.conversations.pinned.pluck(:id)
  end

  test ".reposition ignores conversations outside the collection it is called on" do
    rob_conversation = conversations(:debugging)
    rob_conversation.pin!
    original_position = rob_conversation.pin_position
    greeting = conversations(:greeting).tap(&:pin!)

    users(:keith).conversations.reposition([rob_conversation.id, greeting.id])

    assert_equal original_position, rob_conversation.reload.pin_position
  end

  test ".reposition does not pin a conversation that is not pinned" do
    unpinned = conversations(:ruby_version)
    pinned = conversations(:greeting).tap(&:pin!)

    users(:keith).conversations.reposition([unpinned.id, pinned.id])

    assert_nil unpinned.reload.pin_position
  end

  test ".reposition does not change updated_at" do
    pinned = conversations(:greeting).tap(&:pin!)

    assert_no_changes -> { pinned.reload.updated_at } do
      users(:keith).conversations.reposition([pinned.id])
    end
  end
end
