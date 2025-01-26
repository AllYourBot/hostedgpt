module Toolbox::GoogleTasks::APIHelpers
  extend ActiveSupport::Concern

  private

  def get_lists
    return @lists if @lists.present?

    @lists = refresh_token_if_needed do
      get("https://tasks.googleapis.com/tasks/v1/users/@me/lists").no_params
    end&.items
  end

  def get_list(title)
    list = get_lists&.find { |l| l.title == title }
    raise "Could not find a task list named '#{title}'" if list.nil?
    list
  end

  def default_list
    @default_list ||= get_list("My Tasks")
  end

  def snoozed_list
    @snoozed_list ||= get_list("Snoozed")
  end

  def get_tasks_for_list(list, due_min: nil, due_max: nil)
    refresh_token_if_needed do
      get("https://tasks.googleapis.com/tasks/v1/lists/#{list.id}/tasks").param(
        dueMin: due_min && due_min.strftime("%Y-%m-%dT00:00:00.000Z"),
        dueMax: due_max && (due_max+1.day).strftime("%Y-%m-%dT00:00:00.000Z"),
        showCompleted: false,
        showDeleted: false,
        maxResults: 100,
        fields: "items(id,etag,title,notes,due,links,selfLink,deleted,position)"
      )
    end&.items&.sort { |a,b| a.position <=> b.position }
  end

  def create_task_for_list(list, title:, notes: nil, due: nil)
    refresh_token_if_needed do
      post("https://tasks.googleapis.com/tasks/v1/lists/#{list.id}/tasks").param(
        title:,
        notes:,
        due: format_time(due),
        status: "needsAction",
      )
    end
  end

  def move_task_to_list(task, list, keep_due: true)
    notes = task.try(:notes)
    if link = task.try(:links)&.first&.link
      notes += "\n\n" if notes
      notes = notes.to_s + link
    end # copy links into notes b/c links cannot be added through API creates
    delete_task(task)
    create_task_for_list(list,
      title: task.title,
      notes:,
      due: keep_due.presence && task.try(:due),
    )
  end

  def delete_task(task)
    refresh_token_if_needed do
      delete("https://tasks.googleapis.com/tasks/v1/lists/#{list_id_of(task)}/tasks/#{task.id}").no_params || OpenData.for(task.to_h.merge(deleted: true))
    end
  end

  def update_task(task, title: nil, notes: nil, due: nil, completed: nil, deleted: nil)
    refresh_token_if_needed do
      patch("https://tasks.googleapis.com/tasks/v1/lists/#{list_id_of(task)}/tasks/#{task.id}").param( {
        id: task.id,
        title:,
        notes:,
        due: format_time(due),
        status: !!completed ? "completed" : "needsAction",
        completed: completed.presence && format_time(completed),
        deleted:,
      }.compact) # w/o this it updates values to nil
    end
  end

  def get_task_by_id_or_position(id_or_position, list: nil)
    task = if is_position(id_or_position)
      get_task_by_position(id_or_position, list: list)
    else
      get_task_by_id(id_or_position, list: list)
    end
  end

  def is_position(id_or_position)
    id_or_position = id_or_position.to_i if id_or_position.to_s == id_or_position.to_i.to_s
    id_or_position.is_a?(Integer)
  end

  def get_task_by_position(position_input, list: nil)
    list ||= default_list
    position = position_input.to_i
    tasks = get_tasks_for_list(list)
    begin
      position = position-1 if position > 0
      tasks.fetch(position)
    rescue => e
      raise "Could not find a task at position '#{position_input}'. Position must be a number. Try again or you can get_tasks and lookup by ID instead."
    end
  end

  def get_task_by_id(task_id, list: nil)
    default = list || default_list
    raise "Could not find a task list named '#{list}'" if default.nil?
    begin
      task = get_task_for_list_id(task_id, default.id)
    rescue => e
      raise "Could not find a task with the id '#{task_id}' on the '#{list.title}` list`. Did you intend a different list?" if task.nil?
    end
  end

  def get_task_for_list_id(task_id, list_id)
    refresh_token_if_needed do
      get("https://tasks.googleapis.com/tasks/v1/lists/#{list_id}/tasks/#{task_id}").param(
        fields: "id,etag,title,notes,due,links,selfLink,deleted"
      )
    end
  end

  def list_id_of(task)
    task.selfLink.match(/lists\/(.*)\/tasks/).try(:[], 1)
  end

  def format_time(due)
    if due.is_a?(String) && due == "clear"
      ""
    elsif due.is_a?(String) && due.ends_with?("Z")
      due
    elsif due.is_a?(String)
      DateTime.parse(due).strftime("%Y-%m-%dT00:00:00.000Z")
    elsif due.present?
      due.strftime("%Y-%m-%dT00:00:00.000Z")
    end
  end

  def ensure_boolean(val, error_field:)
    return nil if val.nil?
    return true if val == "true" || val.is_a?(TrueClass)
    return false if val == "false" || val.is_a?(FalseClass)
    raise "#{error_field} is a boolean but it was set to a value other than true or false"
  end

  def task_for_display(task)
    task.to_h.slice(:id, :title, :notes, :due, :status)
  end
end
