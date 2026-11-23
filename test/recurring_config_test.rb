require "test_helper"

class RecurringConfigTest < ActiveSupport::TestCase
  test "recurring.yml declares the scheduled-prompt dispatcher and the finished-job cleanup, all valid" do
    tasks = SolidQueue::Configuration.new.send(:recurring_tasks).index_by(&:key)

    assert_equal %w[clear_finished_jobs run_due_scheduled_prompts], tasks.keys.sort, "SolidQueue should load both recurring tasks"
    tasks.each_value do |task|
      assert task.valid?, "#{task.key} should be a valid recurring task: #{task.errors.full_messages.to_sentence}"
    end
    assert_equal "RunDueScheduledPromptsJob", tasks["run_due_scheduled_prompts"].class_name
  end

  test "the cleanup command runs" do
    command = SolidQueue::Configuration.new.send(:recurring_tasks).find { it.key == "clear_finished_jobs" }.command

    assert_nothing_raised { eval(command) }
  end
end
