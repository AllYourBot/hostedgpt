require "test_helper"

class Toolbox::GoogleCalendarTest < ActiveSupport::TestCase
  setup do
    @google_calendar = Toolbox::GoogleCalendar.new
  end

  test "get_events lists the events between the dates given" do
    stub_get_events do
      response = @google_calendar.get_events(start_date_s: "2026-11-05", end_date_s: "2026-11-06")

      assert_equal "You have 2 events from November 5, 2026 through November 6, 2026.", response[:good_summary], "The summary should count the events and name the dates"
      assert_equal [ "Dentist", "Conference" ], response[:events].map { it[:title] }, "Each event should be listed by title"
      assert response[:undo_by].starts_with?("There is no"), "Listing events needs no undo"
    end
  end

  test "get_events shows an all-day event ending on its LAST day and a timed event at its time" do
    stub_get_events do
      dentist, conference = @google_calendar.get_events(start_date_s: "2026-11-05")[:events]

      assert_equal({ id: "dentist1", title: "Dentist", start: "2026-11-05T15:00:00-08:00", end: "2026-11-05T16:00:00-08:00",
        all_day: false, location: "123 Main St" }, dentist, "The timed event should be shown with its times")
      assert_equal "2026-11-06", conference[:start], "The all-day event starts on its first day"
      assert_equal "2026-11-07", conference[:end], "Google's exclusive end date should be shown as the last day"
      assert conference[:all_day], "The conference is an all-day event"
    end
  end

  test "get_events lists the next 7 days when NO dates are given" do
    travel_to Time.zone.parse("2026-11-05 12:00") do
      stub_get_events do
        response = @google_calendar.get_events

        assert_equal "You have 2 events from November 5, 2026 through November 11, 2026.", response[:good_summary], "Without dates it should cover a week from today"
      end
    end
  end

  test "get_events says there are 0 events when Google returns NO items" do
    stub_get_events(events: { kind: "calendar#events", timeZone: "America/Los_Angeles" }) do
      response = @google_calendar.get_events(start_date_s: "2026-11-05")

      assert_equal [], response[:events], "There should be no events"
      assert response[:good_summary].starts_with?("You have 0 events"), "The summary should say there are none"
    end
  end

  test "get_events fails when the end_date is before the start_date" do
    stub_get_events do
      error = assert_raises { @google_calendar.get_events(start_date_s: "2026-11-05", end_date_s: "2026-11-04") }
      assert_equal "end_date cannot be before start_date.", error.message, "The dates are in the wrong order"
    end
  end

  test "create_event creates an event and can be undone by deleting it" do
    stub_create_event do
      response = @google_calendar.create_event(title_s: "Dentist", start_s: "2026-11-05T15:00:00", location_s: "123 Main St")

      assert_equal "Created the event 'Dentist'.", response[:good_summary], "The summary should name the event"
      assert_equal "dentist1", response[:event][:id], "The created event should be returned"
      assert_equal "https://www.google.com/calendar/event?eid=dentist1", response[:link_url], "It should link to the event"
      assert_equal 'delete_event(event_id: "dentist1")', response[:undo_by], "The undo should delete the new event"
    end
  end

  test "Toolbox.call reaches create_event by its tool name" do
    stub_features(google_tools: true) do
      stub_create_event do
        response = Toolbox.call("googlecalendar_create_event", { "title" => "Dentist", "start" => "2026-11-05T15:00:00" })

        assert_equal "Created the event 'Dentist'.", response[:good_summary], "The tool name should dispatch to create_event"
      end
    end
  end

  test "create_event fails when the time CANNOT be understood" do
    stub_create_event do
      error = assert_raises { @google_calendar.create_event(title_s: "Dentist", start_s: "sometime soon") }
      assert_equal "Could not understand the time 'sometime soon'. Give it like 2026-11-05T15:00:00.", error.message, "The time should be rejected"
    end
  end

  test "change_event can be undone by changing the fields back" do
    stub_change_event(dentist_data(summary: "Dentist checkup")) do
      response = @google_calendar.change_event(event_id_s: "dentist1", title_s: "Dentist checkup", start_s: "2026-11-05T17:00:00")

      assert_equal "Updated the event 'Dentist checkup'.", response[:good_summary], "The summary should use the new title"
      assert_equal 'change_event(event_id: "dentist1", title: "Dentist", start: "2026-11-05T15:00:00-08:00", ' \
        'end: "2026-11-05T16:00:00-08:00")', response[:undo_by], "The undo should restore the title and time"
    end
  end

  test "change_event fails when NOTHING to change is given" do
    stub_change_event do
      error = assert_raises { @google_calendar.change_event(event_id_s: "dentist1") }
      assert_equal "Tell me what to change: a title, start, end, description, or location.", error.message, "There is nothing to change"
    end
  end

  test "change_event fails with a helpful message when the event id is NOT FOUND" do
    stub_get_response(:get_calendar_time_zone, status: 200, response: time_zone_data) do
      stub_get_response(:get_event, status: 404, response: { error: { code: 404, message: "Not Found" } }) do
        Current.set(user: users(:keith)) do
          error = assert_raises { @google_calendar.change_event(event_id_s: "made-up", title_s: "New title") }
          assert_equal "Could not find an event with the id 'made-up'. Try get_events to look up the id.", error.message, "Google's 404 should become a helpful message"
        end
      end
    end
  end

  test "delete_event fails when the event has ALREADY BEEN DELETED" do
    stub_get_response(:get_event, status: 200, response: { kind: "calendar#event", id: "dentist1", status: "cancelled" }) do
      stub_time_zone do
        error = assert_raises { @google_calendar.delete_event(event_id_s: "dentist1") }
        assert_equal "The event with the id 'dentist1' has already been deleted.", error.message, "A cancelled event cannot be deleted again"
      end
    end
  end

  test "delete_event deletes the event and can be undone by creating it again" do
    stub_delete_event do
      response = @google_calendar.delete_event(event_id_s: "dentist1")

      assert response[:good_summary].starts_with?("Deleted the event 'Dentist'."), "The summary should name the event"
      assert_equal 'create_event(title: "Dentist", start: "2026-11-05T15:00:00-08:00", end: "2026-11-05T16:00:00-08:00", ' \
        'location: "123 Main St")', response[:undo_by], "The undo should create the same event again"
    end
  end

  test "event_times reads a time WITHOUT an offset in the calendar's time zone and defaults to one hour" do
    stub_time_zone do
      start_time, end_time = @google_calendar.send(:event_times, "2026-11-05T15:00:00", nil)

      assert_equal({ dateTime: "2026-11-05T15:00:00-08:00", timeZone: "America/Los_Angeles" }, start_time, "3pm should be read as 3pm in the calendar's time zone")
      assert_equal({ dateTime: "2026-11-05T16:00:00-08:00", timeZone: "America/Los_Angeles" }, end_time, "The event should last one hour")
    end
  end

  test "event_times keeps a time WITH an offset at that moment" do
    stub_time_zone do
      start_time, _ = @google_calendar.send(:event_times, "2026-11-05T15:00:00-05:00", nil)

      assert_equal "2026-11-05T12:00:00-08:00", start_time[:dateTime], "3pm Eastern is noon Pacific"
    end
  end

  test "event_times sends Google the day AFTER the last day of an all-day event" do
    stub_time_zone do
      assert_equal [ { date: "2026-11-05" }, { date: "2026-11-06" } ], @google_calendar.send(:event_times, "2026-11-05", nil),
        "A one day event should end the next day"
      assert_equal [ { date: "2026-11-05" }, { date: "2026-11-08" } ], @google_calendar.send(:event_times, "2026-11-05", "2026-11-07"),
        "An event through the 7th should end on the 8th"
    end
  end

  test "event_times keeps the length of an existing event when ONLY the start is given" do
    stub_time_zone do
      timed = OpenData.for(dentist_data)
      _, end_time = @google_calendar.send(:event_times, "2026-11-06T09:00:00", nil, keep_length_of: timed)
      assert_equal "2026-11-06T10:00:00-08:00", end_time[:dateTime], "The one hour event should stay one hour long"

      all_day = OpenData.for(conference_data)
      _, end_date = @google_calendar.send(:event_times, "2026-11-10", nil, keep_length_of: all_day)
      assert_equal({ date: "2026-11-12" }, end_date, "The two day event should stay two days long")
    end
  end

  test "event_times fails when an all-day start is given a timed end" do
    stub_time_zone do
      error = assert_raises { @google_calendar.send(:event_times, "2026-11-05", "2026-11-05T16:00:00") }
      assert_equal "For an all-day event give the end as a date too, like 2026-11-05.", error.message, "Mixing a date and a time should be rejected"
    end
  end

  test "event_times fails when the end is NOT after the start" do
    stub_time_zone do
      error = assert_raises { @google_calendar.send(:event_times, "2026-11-05T15:00:00", "2026-11-05T14:00:00") }
      assert_equal "The end of an event must be after its start.", error.message, "The end is before the start"
    end
  end

  private

  def stub_time_zone(&block)
    stub_get_response(:get_calendar_time_zone, status: 200, response: time_zone_data) do
      Current.set(user: users(:keith)) do
        yield
      end
    end
  end

  def stub_get_events(events: events_data, &block)
    stub_get_response(:get_events_between, status: 200, response: events) do
      stub_time_zone(&block)
    end
  end

  def stub_create_event(&block)
    stub_post_response(:insert_event, status: 200, response: dentist_data) do
      stub_time_zone(&block)
    end
  end

  def stub_change_event(updated = dentist_data, &block)
    stub_get_response(:get_event, status: 200, response: dentist_data) do
      stub_patch_response(:update_event, status: 200, response: updated) do
        stub_time_zone(&block)
      end
    end
  end

  def stub_delete_event(&block)
    stub_get_response(:get_event, status: 200, response: dentist_data) do
      stub_delete_response(:remove_event, status: 204, response: {}) do
        stub_time_zone(&block)
      end
    end
  end

  def time_zone_data
    { timeZone: "America/Los_Angeles" }
  end

  def events_data
    {
      kind: "calendar#events",
      summary: "keith@hostedgpt.com",
      timeZone: "America/Los_Angeles",
      items: [ dentist_data, conference_data ],
    }
  end

  def dentist_data(summary: "Dentist")
    {
      kind: "calendar#event",
      id: "dentist1",
      status: "confirmed",
      htmlLink: "https://www.google.com/calendar/event?eid=dentist1",
      summary:,
      location: "123 Main St",
      start: { dateTime: "2026-11-05T15:00:00-08:00", timeZone: "America/Los_Angeles" },
      end: { dateTime: "2026-11-05T16:00:00-08:00", timeZone: "America/Los_Angeles" },
    }
  end

  def conference_data
    {
      kind: "calendar#event",
      id: "conference1",
      status: "confirmed",
      htmlLink: "https://www.google.com/calendar/event?eid=conference1",
      summary: "Conference",
      start: { date: "2026-11-06" },
      end: { date: "2026-11-08" },
    }
  end
end
