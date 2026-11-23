require "test_helper"

class ScheduledPrompt::PausableTest < ActiveSupport::TestCase
  setup do
    @scheduled_prompt = scheduled_prompts(:morning_briefing)
  end

  test "record_reply counts a FAILED reply and pauses the prompt at the third in a row" do
    2.times { @scheduled_prompt.record_reply(failed_reply) }
    assert_equal 2, @scheduled_prompt.consecutive_failures
    assert @scheduled_prompt.reload.enabled?, "Two failures in a row should not pause the prompt yet"

    @scheduled_prompt.record_reply(failed_reply)
    @scheduled_prompt.reload
    refute @scheduled_prompt.enabled?, "The third failure in a row should pause the prompt"
    assert_nil @scheduled_prompt.next_run_at, "A paused prompt should have no next run"
    assert @scheduled_prompt.paused_for_failures?
  end

  test "record_reply RESETS the count on a successful reply" do
    @scheduled_prompt.update_column(:consecutive_failures, 2)

    @scheduled_prompt.record_reply(reply_to_run)

    assert_equal 0, @scheduled_prompt.reload.consecutive_failures, "A run that worked should start the count over"
  end

  test "record_reply IGNORES a reply that only calls tools, since the run hasn't finished" do
    @scheduled_prompt.update_column(:consecutive_failures, 2)
    reply = reply_to_run
    reply.update_columns(content_tool_calls: [{ id: "call_1", type: "function", function: { name: "helloworld_hi", arguments: "{}" } }])

    @scheduled_prompt.record_reply(reply)

    assert_equal 2, @scheduled_prompt.reload.consecutive_failures, "Only the reply that ends the run should count"
  end

  test "record_reply IGNORES replies after the user joins the conversation" do
    conversation = @scheduled_prompt.run!.conversation
    Current.set(user: users(:keith)) do
      conversation.messages.create!(assistant: assistants(:samantha), content_text: "Thanks, and tomorrow?")
    end
    later_reply = conversation.latest_message_for_version(:latest)
    later_reply.update_columns(failed_at: Time.current)

    @scheduled_prompt.record_reply(later_reply)

    assert_equal 0, @scheduled_prompt.reload.consecutive_failures, "A failure in the user's own follow-up is not the prompt's"
  end

  test "paused_for_failures? is false for a prompt the user paused THEMSELVES" do
    @scheduled_prompt.update!(enabled: false)
    refute @scheduled_prompt.paused_for_failures?
  end

  test "re-enabling a paused prompt forgets its failures" do
    3.times { @scheduled_prompt.record_reply(failed_reply) }

    @scheduled_prompt.update!(enabled: true)

    assert_equal 0, @scheduled_prompt.consecutive_failures, "A resumed prompt should get three fresh tries"
    assert @scheduled_prompt.next_run_at.future?, "Re-enabling should schedule the next run"
  end

  private

  def reply_to_run
    conversation = @scheduled_prompt.run!.conversation
    conversation.latest_message_for_version(:latest).tap { it.update_columns(content_text: "Sunny, and nothing on your calendar.") }
  end

  def failed_reply
    reply_to_run.tap { it.update_columns(content_text: "(I received a blank response.)", failed_at: Time.current) }
  end
end
