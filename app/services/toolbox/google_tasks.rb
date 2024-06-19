class Toolbox::GoogleTasks < Toolbox
  include GoogleApp
  include ActionView::Helpers::DateHelper

  describe :create_task_on_list, <<~S
    When the user says "add something to my todo list" or task list. Creates a new task on a list. The title is required, but the other fields
    are optional (note, due date, and list). If no list is specified it will default to the default "My Tasks" list.
  S

  def create_task_on_list(title_s:, notes_s: nil, due_date_s: nil, list_s: "My Tasks")
    lists = get_lists
    list = pick_best(input: list_s, options: lists, key: :title, error_type: "task list")
    task = create_task_for(list, title: title_s, notes: notes_s, due: due_date_s)

    date_str = task.try(:due) && " It's due on #{time_ago_in_words(DateTime.parse(task.due)).to_date}"
    {
      good_summary: "Created the task '#{task.title}' on the list '#{list.title}'.#{date_str}",
      list: list.title,
      task_title: task.title,
      task_notes: task.try(:notes),
      task_due: task.try(:due),
    }
  end

  describe :refresh_tasks, <<~S
    When the user says "check my tasks" or "what's on my todo list" or refresh tasks or something similar. This returns all the current open
    tasks that need to be completed.
  S

  def refresh_tasks
    lists = get_lists
    default = lists.find { |l| l.title == "My Tasks"}
    snoozed = lists.find { |l| l.title == "Snoozed"}
    raise "Could not find a task list named 'My Tasks'" if default.nil?
    raise "Could not find a task list named 'Snoozed'" if snoozed.nil?

    loop do
      tasks_to_snooze = get_tasks_for(default, due_min: Date.tomorrow)
      tasks_to_snooze.each do |task|
        move_task_to_list(task, snoozed)
      end
      break if tasks_to_snooze.length < 100
    end

    loop do
      tasks_to_unsnooze = get_tasks_for(snoozed, due_max: Date.today)
      tasks_to_unsnooze.each do |task|
        move_task_to_list(task, default, keep_due: false)
      end
      break if tasks_to_unsnooze.length < 100
    end

    tasks = get_tasks_for(default).map { |t| t.to_h.slice(:id, :title, :notes, :due) }
    {
      good_summary: "You have #{tasks.length} items on your task list for today.",
      tasks: tasks
    }
  end

  private

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

  def get_lists
    refresh_token_if_needed do
      get("https://tasks.googleapis.com/tasks/v1/users/@me/lists").no_params
    end&.items
  end

  def get_tasks_for(list, due_min: nil, due_max: nil)
    refresh_token_if_needed do
      get("https://tasks.googleapis.com/tasks/v1/lists/#{list.id}/tasks").param(
        dueMin: due_min && due_min.strftime("%Y-%m-%dT00:00:00.000Z"),
        dueMax: due_max && (due_max+1.day).strftime("%Y-%m-%dT00:00:00.000Z"),
        showCompleted: false,
        showDeleted: false,
        maxResults: 100,
        fields: "items(id,etag,title,notes,due,links,selfLink)"
      )
    end&.items
  end

  def delete_task(task)
    refresh_token_if_needed do
      delete("https://tasks.googleapis.com/tasks/v1/lists/#{list_of(task)}/tasks/#{task.id}").no_params
    end
  end

  def create_task_for(list, title:, notes: nil, due: nil)
    due_formatted = if due.is_a?(String) && due.ends_with?("Z")
      due
    elsif due.is_a?(String)
      DateTime.parse(due).strftime("%Y-%m-%dT00:00:00.000Z")
    elsif due.present?
      due.strftime("%Y-%m-%dT00:00:00.000Z")
    end

    refresh_token_if_needed do
      post("https://tasks.googleapis.com/tasks/v1/lists/#{list.id}/tasks").param(
        title: title,
        notes: notes,
        due: due_formatted,
        status: "needsAction",
      )
    end
  end

  def move_task_to_list(task, list, keep_due: true)
    notes = task.try(:notes)
    if link = task.try(:links)&.first&.link
      notes += "\n\n" if notes
      notes = notes.to_s + link
    end
    delete_task(task)
    create_task_for(list,
      title: task.title,
      notes: notes,
      due: keep_due.presence && task.try(:due),
    )
  end

  def list_of(task)
    task.selfLink.match(/lists\/(.*)\/tasks/).try(:[], 1)
  end

  def app_credential
    Current.user&.google_tasks_credential
  end
end
