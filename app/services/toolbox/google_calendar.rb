class Toolbox::GoogleCalendar < Toolbox
  include GoogleApp

  # This Tool works on the user's primary Google Calendar. A time given without a UTC offset is read in that calendar's
  # own time zone. An all-day event is given by dates alone (e.g. "2026-11-05") and its end is the LAST day of the event;
  # Google stores the day after, so that conversion happens here in both directions.

  # Manual test plan
  #
  # [ ] Ask what's on your calendar. Confirm it lists the next 7 days of events, including all-day ones.
  # [ ] Ask what's on your calendar on a specific day next week. Confirm only that day's events are listed.
  # [ ] Create an event with a title, time, location, and description. Confirm it appears for one hour at that time.
  # [ ] Undo that event. Confirm it disappears.
  # [ ] Create an all-day event spanning two days. Confirm it covers both days and no more.
  # [ ] Move an event to another time without giving an end. Confirm it keeps its length.
  # [ ] Undo that change. Confirm it goes back.
  # [ ] Delete an event. Confirm it disappears. Undo that. Confirm it's created again with the same details.

  describe :get_events, <<~S
    Lists the events on the user's Google Calendar. Call when the user says "what's on my calendar" or "am I free on Friday"
    or "what meetings do I have next week" or something similar. Both dates are optional and given like "2026-11-05". Without
    them it lists the next 7 days starting today. end_date is the last day included.
  S

  def get_events(start_date_s: nil, end_date_s: nil)
    first_day = start_date_s.present? ? parse_date(start_date_s) : Time.current.in_time_zone(zone).to_date
    last_day = end_date_s.present? ? parse_date(end_date_s) : first_day + 6.days
    raise "end_date cannot be before start_date." if last_day < first_day

    events = get_events_between(first_day.in_time_zone(zone), (last_day + 1.day).in_time_zone(zone))
      .map { event_for_display(it) }

    {
      message_to_user: "Google Calendar",
      good_summary: "You have #{events.length} events from #{long_date(first_day)} through #{long_date(last_day)}.",
      events: events,
      undo_by: "There is no need to undo this",
    }
  end

  describe :create_event, <<~S
    Creates an event on the user's Google Calendar. When the user says "add this to my calendar" or "schedule a meeting" or
    "put a reminder on my calendar for". The title and start are required. Give start and end like "2026-11-05T15:00:00",
    or give dates alone like "2026-11-05" for an all-day event, in which case end is the last day of the event. Without an
    end, a timed event lasts one hour and an all-day event lasts one day.
  S

  def create_event(title_s:, start_s:, end_s: nil, description_s: nil, location_s: nil)
    start_time, end_time = event_times(start_s, end_s)
    event = insert_event(summary: title_s, description: description_s, location: location_s, start: start_time, end: end_time)

    {
      message_to_user: "Google Calendar",
      link_url: event.try(:htmlLink),
      good_summary: "Created the event '#{event.summary}'.",
      event: event_for_display(event),
      undo_by: undo_event(:delete_event, event_id: event.id),
    }.compact
  end

  describe :change_event, <<~S
    Changes the title, time, description, or location of an event on the user's Google Calendar. When the user says
    "move my meeting to 3pm" or "rename this event" or "add the address to this event". event_id is required and comes from
    get_events. Only pass the fields that change. Times are given the same way as for create_event. If only the start changes,
    the event keeps its length.
  S

  def change_event(event_id_s:, title_s: nil, start_s: nil, end_s: nil, description_s: nil, location_s: nil)
    event = get_event(event_id_s)
    before = event_for_display(event)

    changes = { summary: title_s, description: description_s, location: location_s }.compact
    if start_s.present? || end_s.present?
      changes[:start], changes[:end] = event_times(start_s.presence || before[:start], end_s, keep_length_of: event)
    end
    raise "Tell me what to change: a title, start, end, description, or location." if changes.empty?

    updated_event = update_event(event, **changes)

    params = {
      event_id: updated_event.id,
      title: title_s && before[:title].to_s,
      start: changes[:start] && before[:start],
      end: changes[:end] && before[:end],
      description: description_s && before[:description].to_s,
      location: location_s && before[:location].to_s,
    }.compact

    {
      message_to_user: "Google Calendar",
      link_url: updated_event.try(:htmlLink),
      good_summary: "Updated the event '#{updated_event.summary}'.",
      event: event_for_display(updated_event),
      undo_by: undo_event(:change_event, params),
    }.compact
  end

  describe :delete_event, <<~S
    Deletes an event from the user's Google Calendar. When the user says "cancel my meeting" or "remove this from my calendar".
    event_id is required and comes from get_events. This action is destructive so ALWAYS confirm with the user which event
    you are about to delete, by its title and time, before calling this.
  S

  def delete_event(event_id_s:)
    event = get_event(event_id_s)
    remove_event(event)
    deleted = event_for_display(event)

    params = deleted.slice(:title, :start, :end, :description, :location)

    {
      message_to_user: "Google Calendar",
      good_summary: "Deleted the event '#{deleted[:title]}'. This action is destructive so ALWAYS tell the user this title.",
      undo_by: undo_event(:create_event, params),
    }
  end

  private

  def zone
    @zone ||= ActiveSupport::TimeZone[get_calendar_time_zone.to_s] || Time.zone
  end

  def get_calendar_time_zone
    refresh_token_if_needed do
      get(events_url).param(maxResults: 1, fields: "timeZone")
    end&.try(:timeZone)
  end

  def get_events_between(time_min, time_max)
    refresh_token_if_needed do
      get(events_url).param(
        timeMin: time_min.iso8601,
        timeMax: time_max.iso8601,
        timeZone: zone.tzinfo.name,
        singleEvents: true,
        orderBy: "startTime",
        maxResults: 100,
      )
    end&.try(:items) || [] # Google omits the key when nothing matches
  end

  def get_event(event_id)
    event = refresh_token_if_needed do
      get(events_url(event_id)).param(timeZone: zone.tzinfo.name)
    end
    raise "The event with the id '#{event_id}' has already been deleted." if event.try(:status) == "cancelled"
    event
  rescue SDK::Verb::ResponseError => e
    raise "Could not find an event with the id '#{event_id}'. Try get_events to look up the id." if e.status.in?([400, 404, 410])
    raise
  end

  def insert_event(**event)
    refresh_token_if_needed do
      post(events_url).param(event.compact)
    end
  end

  def update_event(event, **changes)
    refresh_token_if_needed do
      patch(events_url(event.id)).param(changes)
    end
  end

  def remove_event(event)
    refresh_token_if_needed do
      delete(events_url(event.id)).no_params
    end
  end

  def events_url(event_id = nil)
    url = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
    event_id ? "#{url}/#{ERB::Util.url_encode(event_id)}" : url
  end

  # The start and end of an event as Google expects them. keep_length_of is an existing event whose length to keep when
  # no end is given; without it a timed event lasts an hour and an all-day event lasts a day.
  def event_times(start_s, end_s, keep_length_of: nil)
    date_only?(start_s) ? all_day_times(start_s, end_s, keep_length_of) : timed_times(start_s, end_s, keep_length_of)
  end

  def all_day_times(start_s, end_s, keep_length_of)
    raise "For an all-day event give the end as a date too, like 2026-11-05." if end_s.present? && !date_only?(end_s)

    first_day = parse_date(start_s)
    last_day = if end_s.present?
      parse_date(end_s)
    elsif keep_length_of&.start.try(:date)
      first_day + (Date.parse(keep_length_of.end.date) - Date.parse(keep_length_of.start.date) - 1).days
    else
      first_day
    end
    raise "The end of an event cannot be before its start." if last_day < first_day

    [ { date: first_day.iso8601 }, { date: (last_day + 1.day).iso8601 } ]
  end

  def timed_times(start_s, end_s, keep_length_of)
    raise "For an event at a time give the end as a time too, like 2026-11-05T16:00:00." if end_s.present? && date_only?(end_s)

    starts_at = parse_time(start_s)
    ends_at = if end_s.present?
      parse_time(end_s)
    elsif keep_length_of&.start.try(:dateTime)
      starts_at + (Time.iso8601(keep_length_of.end.dateTime) - Time.iso8601(keep_length_of.start.dateTime))
    else
      starts_at + 1.hour
    end
    raise "The end of an event must be after its start." if ends_at <= starts_at

    [ starts_at, ends_at ].map { { dateTime: it.iso8601, timeZone: zone.tzinfo.name } }
  end

  def long_date(date) = date.strftime("%B %-d, %Y")

  def date_only?(value) = value.to_s.strip.match?(/\A\d{4}-\d{2}-\d{2}\z/)

  def parse_date(value)
    Date.parse(value.to_s)
  rescue Date::Error
    raise "Could not understand the date '#{value}'. Give it like 2026-11-05."
  end

  def parse_time(value)
    zone.parse(value.to_s) || raise(ArgumentError)
  rescue ArgumentError
    raise "Could not understand the time '#{value}'. Give it like 2026-11-05T15:00:00."
  end

  def event_for_display(event)
    all_day = event.start.try(:date).present?

    {
      id: event.id,
      title: event.try(:summary),
      start: all_day ? event.start.date : event.start.try(:dateTime),
      end: all_day ? (Date.parse(event.end.date) - 1.day).iso8601 : event.end.try(:dateTime),
      all_day: all_day,
      description: event.try(:description),
      location: event.try(:location),
    }.compact
  end

  def undo_event(name, params)
    "#{name}(#{params.compact.map { |k, v| "#{k}: \"#{v.to_s.gsub('"', '\"')}\"" }.join(", ")})"
  end

  def app_credential = Current.user&.google_calendar_credential
end
