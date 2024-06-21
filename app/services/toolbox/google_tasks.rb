class Toolbox::GoogleTasks < Toolbox
  include GoogleApp, APIHelpers
  include ActionView::Helpers::DateHelper

  # This Tool assumes you have two special Google Tasks lists: "My Tasks" and "Snoozed". You may have any other additional lists. When a task
  # from My Tasks gets a future due date set, it's automatically moved to Snoozed and it will come back to My Tasks on that date. Tasks on any
  # other lists will always stay on that list regardless of the due date set.

  # Manual test plan
  #
  # [ ] Create a task without specifying list. Confirm it appears.
  # [ ] Undo that task. Confirm it disappears.
  # [ ] Create a task without specifying a list and include a note and future due date. Confirm it appears on snoozed.
  # [ ] Undo that task. Confirm it disappears.
  # [ ] Create a task by specifying a special list and specifying a future due date. Confirm it appears on the list.
  # [ ] Undo that task. Confirm it disappears.

#          * always tell the user this title didn't work

  # [ ] Make sure you have a dummy task on your main list and delete it using the position. Confirm it disappears.
  # [ ] Undo that deletion passing in the position. Confirm you get an error.
  # [ ] Undo that deletion passing in the ID. Confirm it reappears.

  # [ ] Change a task on the main list by referencing it's position and add a future due date. Confirm it moves to snoozed.
  # [ ] Undo this. Confirm it comes back.
  # [ ] Change the LAST task on the main list by referencing it's position as -1 and change it to be completed. Confirm it disappears.
  # [ ] Undo that deletion passing in the position. Confirm you get an error.
  # [ ] Undo that deletion passing in the ID. Confirm it reappears.
  # [ ] Change a task on another list by position by specifying a new title and note and specify the list WITH A TYPO. Confirm it updates.
  # [ ] Undo this. Confirm it reverts.
  # [ ] Change a future task which is already on snoozed to have a due date of today, confirm it comes back to main and clears due.

  # [ ] Create a task on the main list title "from main" and set a due date into the future. Create a task on Snoozed titled "from snoozed"
  #     with today's date. Get tasks. Confirm they switch places and the one returning to the main list gets it's date cleared.

  describe :create_task_on_list, <<~S
    When the user says "add something to my todo list" or task list. Creates a new task on a list. The title is required, but the other fields
    are optional (note, due date, and list). If no list is specified it will default to the default "My Tasks" list.
  S

  def create_task_on_list(title_s:, notes_s: nil, due_date_s: nil, list_s: "My Tasks")
    if list_s == "My Tasks" && format_time(due_date_s).present? && Date.parse(format_time(due_date_s)) > Time.zone.today
      list = snoozed_list
    else
      list = pick_best(input: list_s, options: get_lists, key: :title, error_type: "task list")
    end
    task = create_task_for_list(list, title: title_s, notes: notes_s, due: due_date_s)

    params = {
      task_id_or_position: task.id,
      deleted: true,
      list: (list.title != "My Tasks").presence && list.title
    }.compact

    date_str = task.try(:due) && " It's due in #{time_ago_in_words(DateTime.parse(task.due))}"
    {
      good_summary: "Created the task '#{task.title}' on the list '#{list.title}'.#{date_str}",
      task: task_for_display(task).merge(list: list.title),
      undo_by: undo_task(:remove_or_restore_task, params),
    }
  end

  describe :remove_or_restore_task, <<~S
    Removes the task (or restores the task if it's already removed). When the user says "delete this task" or "take it off my task list" or some reference to
    removing. The field task_id_or_position is required and should either be the alphanumeric ID string or this can be an integer. Try to use ID whenever you can!
    If the user references a position this is ordinal not index. If the user says "Remove the second item on my list as completed" then set
    task_id_or_position_s to 2. If the user says "first" use 1, if they say "last" you can use -1 or "second to last" use -2 or "third from the bottom" use -3.
  S

  def remove_or_restore_task(task_id_or_position_s:, is_deleted:, list_s: "My Tasks")
    is_deleted = ensure_boolean(is_deleted, error_field: "is_deleted")
    raise "To restore you must call remove_or_restore_task with a task ID." if is_position(task_id_or_position_s) && !is_deleted
    list = pick_best(input: list_s, options: get_lists, key: :title, error_type: "task list")

    task = get_task_by_id_or_position(task_id_or_position_s, list: list)
    if !!task.try(:deleted)
      task = update_task(task, deleted: false)
    else
      task = delete_task(task)
    end

    is_deleted = !!task.try(:deleted)

    params = {
      task_id_or_position: task.id,
      deleted: !is_deleted,
      list: (list.title != "My Tasks").presence && list.title
    }.compact

    {
      good_summary: "#{is_deleted ? 'Removed' : 'Restored'} '#{task.title}'. This action is destructive so ALWAYS tell the user this title.",
      task: (!is_deleted).presence && task_for_display(task),
      undo_by: undo_task(:remove_or_restore_task, params),
    }.compact
  end

  describe :change_task, <<~S
    Change the title, note, or due date of a task. When the user says "change this task to" then change it's title. When they say "add a note to
    this task" do that. When they say "snooze this task" then change it's due date, for "clear or remove the date" set due_date to "clear". When
    they say "mark this as done" or "I completed this" then set is_completed to true. The only required field is task_id_or_position and this
    should either be the alphanumeric ID string or this can be an integer. Try to use ID whenever you can!
    If the user references a position this is ordinal not index. If the user says "Remove the second item on my list as completed" then set
    task_id_or_position_s to 2. If the user says "first" use 1, if they say "last" you can use -1 or "second to last" use -2 or "third from the bottom" use -3.
  S

  def change_task(task_id_or_position_s:, title_s: nil, notes_s: nil, due_date_s: nil, is_completed: nil, list_s: "My Tasks")
    is_completed = ensure_boolean(is_completed, error_field: "is_completed")
    raise "To uncomplete you must call change_task with a task ID." if is_position(task_id_or_position_s) && is_completed == false
    list = pick_best(input: list_s, options: get_lists, key: :title, error_type: "task list")
    task = get_task_by_id_or_position(task_id_or_position_s, list: list)

    updated_task = update_task(task,
      title: title_s,
      notes: notes_s,
      due: due_date_s,
      completed: is_completed && Time.current,
    )

    if (list.title == "My Tasks" && format_time(due_date_s).present? && updated_task.try(:due)&.to_date > Date.today)
      updated_task = move_task_to_list(updated_task, snoozed_list)
      list = snoozed_list
    end
    if (list.title == "Snoozed" && (
          (format_time(due_date_s).present? && updated_task.try(:due)&.to_date == Date.today) ||
          (due_date_s == "clear" && updated_task.try(:due).nil?)
    ))
      updated_task = move_task_to_list(updated_task, default_list, keep_due: false)
    end

    params = {
      task_id_or_position: updated_task.id,
      title: title_s && task.try(:title).to_s,
      notes: notes_s && task.try(:notes).to_s,
      due_date: due_date_s && (task.try(:due) || "clear"),
      completed: is_completed.nil? ? nil : is_completed == false,
      list: (list.title != "My Tasks").presence && list.title
    }.compact

    {
      good_summary: "Updated '#{updated_task.title}'",
      undo_by: undo_task(:change_task, params),
    }
  end

  describe :get_tasks, <<~S
    This returns all the current open tasks that need to be completed. Call when the user says "refresh tasks" or "check my tasks" or "what's on
    my todo list" or something similar.
  S

  def get_tasks(list_s: "My Tasks")
    refresh_tasks
    list = pick_best(input: list_s, options: get_lists, key: :title, error_type: "task list")
    tasks = get_tasks_for_list(list).map.with_index { |t, i| task_for_display(t).merge(position: i+1, list: list.title) }
    {
      good_summary: "You have #{tasks.length} items on your '#{list.title}' list.",
      tasks: tasks,
      undo_by: "There is no need to undo this",
    }
  end

  private

  def refresh_tasks # this should happen on a cron interval instead
    loop do
      tasks_to_snooze = get_tasks_for_list(default_list, due_min: Date.tomorrow)
      tasks_to_snooze.each do |task|
        move_task_to_list(task, snoozed_list)
      end
      break if tasks_to_snooze.length < 100
    end

    loop do
      tasks_to_unsnooze = get_tasks_for_list(snoozed_list, due_max: Date.today)
      tasks_to_unsnooze.each do |task|
        move_task_to_list(task, default_list, keep_due: false)
      end
      break if tasks_to_unsnooze.length < 100
    end
  end

  def pick_best(input:, options: [], key:, error_type:)
    option_names = options.map { |o| o.send(key) }
    input_matcher = Amatch::JaroWinkler.new(input)
    options_hash = option_names.each_with_index.to_h { |value, index| [index, value] }
    options_hash.each do |index, option|
      options_hash[index] = input_matcher.match(option)
    end

    highest_match_sort_with_lowest_index_tiebreaker = options_hash.sort do |a,b|
      [b.second, a.first] <=> [a.second, b.first]
    end

    index = highest_match_sort_with_lowest_index_tiebreaker.filter { |pair| pair.second > 0.8 }&.first&.first # returns the index
    raise "Unable to find a #{error_type} with the name '#{input}'" if index.nil?
    options[index]
  end

  def undo_task(name, params)
    "#{name}(#{params.map { |k,v| "#{k}: \"#{v.to_s.gsub('"', '\"')}\"" }.join(", ")})"
  end

  def app_credential
    Current.user&.google_tasks_credential
  end
end
