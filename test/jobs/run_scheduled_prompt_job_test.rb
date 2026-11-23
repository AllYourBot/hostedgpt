require "test_helper"

class RunScheduledPromptJobTest < ActiveJob::TestCase
  test "perform posts the prompt & queues the assistant's reply" do
    assert_difference "Message.count", 2, "The user's message and the empty reply should be created" do
      assert_enqueued_with(job: GetNextAIMessageJob) do
        RunScheduledPromptJob.perform_now(scheduled_prompts(:morning_briefing))
      end
    end
    assert_equal scheduled_prompts(:morning_briefing).prompt, Message.user.last.content_text
  end

  test "perform is DISCARDED when the prompt was deleted after it was queued" do
    scheduled_prompt = scheduled_prompts(:morning_briefing)
    RunScheduledPromptJob.perform_later(scheduled_prompt)
    scheduled_prompt.destroy!

    assert_no_difference "Message.count" do
      perform_enqueued_jobs(only: RunScheduledPromptJob)
    end
  end
end
