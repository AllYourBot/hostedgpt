require "test_helper"

class RunDueScheduledPromptsJobTest < ActiveJob::TestCase
  setup do
    @scheduled_prompt = scheduled_prompts(:morning_briefing)
  end

  test "perform queues a run for each due prompt & moves its next run on" do
    @scheduled_prompt.update_column(:next_run_at, 1.minute.ago)

    assert_enqueued_with(job: RunScheduledPromptJob, args: [@scheduled_prompt]) do
      RunDueScheduledPromptsJob.perform_now
    end
    assert @scheduled_prompt.reload.next_run_at.future?, "The prompt should not be due again until its next run"
  end

  test "perform queues NOTHING when no prompt is due" do
    assert_no_enqueued_jobs(only: RunScheduledPromptJob) do
      RunDueScheduledPromptsJob.perform_now
    end
  end

  test "perform runs a prompt that was missed while the app was down ONLY ONCE" do
    @scheduled_prompt.update_column(:next_run_at, 3.days.ago)

    assert_enqueued_jobs 1, only: RunScheduledPromptJob do
      RunDueScheduledPromptsJob.perform_now
      RunDueScheduledPromptsJob.perform_now
    end
  end
end
