require "test_helper"

class ScheduledPromptTest < ActiveSupport::TestCase
  # Association tests

  test "has an associated user" do
    assert_instance_of User, scheduled_prompts(:morning_briefing).user
  end

  test "has an associated assistant" do
    assert_instance_of Assistant, scheduled_prompts(:morning_briefing).assistant
  end

  test "ordered lists scheduled prompts oldest first" do
    newer = users(:keith).scheduled_prompts.create!(assistant: assistants(:samantha), prompt: "Weekly recap", schedule: "every friday at 5pm")
    assert_equal [scheduled_prompts(:morning_briefing), newer], users(:keith).scheduled_prompts.ordered.to_a,
      "The newest scheduled prompt should be listed last"
  end

  # Creation tests

  test "create with minimal possible attributes" do
    assert_nothing_raised do
      ScheduledPrompt.create!(user: users(:keith), assistant: assistants(:samantha), prompt: "Hi", schedule: "0 9 * * *")
    end
  end

  test "new enforces all required attributes and formatting" do
    scheduled_prompt = ScheduledPrompt.new
    refute scheduled_prompt.valid?, "A scheduled prompt without a user, assistant, prompt or schedule should be invalid"
    assert_equal ["must exist"], scheduled_prompt.errors[:user]
    assert_equal ["must exist"], scheduled_prompt.errors[:assistant]
    assert_equal ["can't be blank"], scheduled_prompt.errors[:prompt]
    assert_equal ["can't be blank"], scheduled_prompt.errors[:schedule]

    scheduled_prompt = ScheduledPrompt.new(user: users(:keith), assistant: assistants(:rob_gpt4), prompt: "Hi", schedule: "0 9 * * *")
    refute scheduled_prompt.valid?, "A scheduled prompt should not run another user's assistant"
    assert_equal ["is invalid"], scheduled_prompt.errors[:assistant]
  end

  # Destroy test

  test "scheduled prompts are destroyed with their user and with their assistant" do
    assert_difference "ScheduledPrompt.count", -assistants(:samantha).scheduled_prompts.count, "The assistant's prompts should go with it" do
      assistants(:samantha).destroy
    end

    users(:keith).scheduled_prompts.create!(assistant: assistants(:keith_gpt4), prompt: "Hi", schedule: "every day at noon")
    assert_difference "ScheduledPrompt.count", -users(:keith).scheduled_prompts.count, "The user's prompts should go with them" do
      users(:keith).destroy
    end
  end

  # Method tests

  test "run! posts the prompt in a new conversation & queues the assistant's reply" do
    scheduled_prompt = scheduled_prompts(:morning_briefing)

    message = nil
    assert_difference "Conversation.count", 1, "Each run should start its own conversation" do
      assert_enqueued_with(job: GetNextAIMessageJob) do
        message = scheduled_prompt.run!
      end
    end

    assert message.user?, "The prompt should be posted as the user's message"
    assert_equal scheduled_prompt.prompt, message.content_text
    assert_equal users(:keith), message.conversation.user, "The conversation should belong to the prompt's user"
    assert_equal assistants(:samantha), message.conversation.assistant
    assert message.conversation.unread?, "The user didn't watch it run, so the conversation should be marked unread"
    assert_nil Current.user, "run! should not leave Current.user set for the rest of the job"
  end
end
