require "test_helper"

class ScheduledPrompt::SchedulableTest < ActiveSupport::TestCase
  setup do
    @scheduled_prompt = scheduled_prompts(:morning_briefing)
  end

  test "due includes an enabled prompt whose next run HAS PASSED" do
    @scheduled_prompt.update_column(:next_run_at, 1.minute.ago)
    assert_includes ScheduledPrompt.due, @scheduled_prompt
  end

  test "due excludes a prompt whose next run is STILL AHEAD" do
    @scheduled_prompt.update_column(:next_run_at, 1.minute.from_now)
    refute_includes ScheduledPrompt.due, @scheduled_prompt
  end

  test "due excludes a DISABLED prompt" do
    @scheduled_prompt.update_columns(next_run_at: 1.minute.ago, enabled: false)
    refute_includes ScheduledPrompt.due, @scheduled_prompt
  end

  test "due excludes a prompt whose assistant WAS DELETED" do
    @scheduled_prompt.update_column(:next_run_at, 1.minute.ago)
    @scheduled_prompt.assistant.update_column(:deleted_at, Time.current)
    refute_includes ScheduledPrompt.due, @scheduled_prompt
  end

  test "due looks at the whole table even when chained onto ONE user's prompts" do
    @scheduled_prompt.update_column(:next_run_at, 1.minute.ago)
    assert_equal [@scheduled_prompt], users(:keith).scheduled_prompts.due.to_a
    assert_empty users(:rob).scheduled_prompts.due, "Another user's prompts should not leak into the chained scope"
  end

  test "the time zone defaults to the app's" do
    assert_equal Time.zone.name, ScheduledPrompt.new.time_zone
  end

  test "the schedule must be RECOGNIZED" do
    @scheduled_prompt.schedule = "whenever you feel like it"
    refute @scheduled_prompt.valid?
    assert_equal ["isn't a schedule we recognize"], @scheduled_prompt.errors[:schedule]
  end

  test "the schedule must not run MORE OFTEN than every 15 minutes" do
    @scheduled_prompt.schedule = "every 5 minutes"
    refute @scheduled_prompt.valid?
    assert_equal ["can't run more often than every 15 minutes"], @scheduled_prompt.errors[:schedule]

    @scheduled_prompt.schedule = "*/15 * * * *"
    assert @scheduled_prompt.valid?, "Every 15 minutes should be allowed"
  end

  test "the time zone must be ONE RAILS KNOWS" do
    @scheduled_prompt.time_zone = "Mars/Olympus_Mons"
    refute @scheduled_prompt.valid?
    assert_equal ["is not included in the list"], @scheduled_prompt.errors[:time_zone]
  end

  test "the time zone may be ANY US ZONE the form offers, including IANA names like America/Detroit" do
    ActiveSupport::TimeZone.us_zones.each do |zone|
      @scheduled_prompt.time_zone = zone.name
      assert @scheduled_prompt.valid?, "#{zone.name} is offered in the form, so it should be accepted"
    end
  end

  test "saving reads the schedule in the prompt's TIME ZONE" do
    travel_to Time.utc(2026, 11, 23, 12) do # a Monday, 6am in Chicago
      @scheduled_prompt.update!(schedule: "every day at 8am", time_zone: "Central Time (US & Canada)")
      assert_equal Time.utc(2026, 11, 23, 14), @scheduled_prompt.next_run_at, "8am Central is 14:00 UTC"

      @scheduled_prompt.update!(time_zone: "Pacific Time (US & Canada)")
      assert_equal Time.utc(2026, 11, 23, 16), @scheduled_prompt.next_run_at, "Changing the time zone should reschedule"
    end
  end

  test "saving accepts a CRON schedule" do
    travel_to Time.utc(2026, 11, 23, 12) do
      @scheduled_prompt.update!(schedule: "30 9 * * 1", time_zone: "UTC")
      assert_equal Time.utc(2026, 11, 30, 9, 30), @scheduled_prompt.next_run_at, "The next Monday at 9:30"
    end
  end

  test "disabling clears the next run and enabling schedules it again" do
    @scheduled_prompt.update!(enabled: false)
    assert_nil @scheduled_prompt.next_run_at, "A disabled prompt should have no next run"

    @scheduled_prompt.update!(enabled: true)
    assert @scheduled_prompt.next_run_at.future?, "Re-enabling should schedule the next run"
  end

  test "claim! moves the next run on & records the run" do
    travel_to Time.utc(2026, 11, 23, 14) do # 8am Central, a weekday
      @scheduled_prompt.update_column(:next_run_at, Time.current)

      assert @scheduled_prompt.claim!, "An unclaimed run should be claimed"
      @scheduled_prompt.reload
      assert_equal Time.utc(2026, 11, 24, 14), @scheduled_prompt.next_run_at, "The next run should be the following weekday at 8am"
      assert_equal Time.current, @scheduled_prompt.last_run_at
    end
  end

  test "claim! FAILS when another dispatcher already claimed the run" do
    @scheduled_prompt.update_column(:next_run_at, 1.minute.ago)
    stale = ScheduledPrompt.find(@scheduled_prompt.id)

    assert @scheduled_prompt.claim!
    refute stale.claim!, "The same run should not be claimed twice"
  end
end
