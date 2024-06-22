require "test_helper"

class Toolbox::GoogleTasksTest < ActiveSupport::TestCase
  setup do
    @google_tasks = Toolbox::GoogleTasks.new
  end

  test "create_task_on_list creates when called with just title" do
    input = {
      title: "do this"
    }
    stub_create_task_on_list(input) do
      response = @google_tasks.create_task_on_list(title_s: input[:title])

      assert response[:good_summary].length > 10
      assert_task_equal input, response[:task]
      assert response[:undo_by].starts_with?("remove_or_restore_task")
    end
  end

  test "create_task_on_list creates a task on another list" do
    input = {
      title: "do this",
      notes: "a note",
      list: "Kid Projects",
    }
    stub_create_task_on_list(input) do
      response = @google_tasks.create_task_on_list(
        title_s: input[:title],
        notes_s: input[:note],
        list_s: input[:list]
      )
      assert response[:good_summary].length > 10
      assert_task_equal input, response[:task]
      assert response[:undo_by].starts_with?("remove_or_restore_task")
    end
  end

  test "create_task_on_list succeeds when small typo in list name" do
    input = {
      title: "do this",
      list: "The Kids Projects"
    }
    stub_create_task_on_list(input) do
      response = @google_tasks.create_task_on_list(title_s: input[:title], list_s: input[:list])
      input[:list] = "Kid Projects"

      assert response[:good_summary].length > 10
      assert_task_equal input, response[:task]
      assert response[:undo_by].starts_with?("remove_or_restore_task")
      assert response[:undo_by].include?("list: \"#{input[:list]}\"")

    end
  end

  test "create_task_on_list with a future date creates an item on snooze" do
    input = {
      title: "do this",
      due: 1.week.from_now.strftime("%Y-%m-%dT00:00:00.000Z"),
    }
    stub_create_task_on_list(input) do
      response = @google_tasks.create_task_on_list(title_s: input[:title], due_date_s: input[:due])
      input[:list] = "Snoozed"
      input[:status] = "needsAction"

      assert response[:good_summary].length > 10
      assert_task_equal input, response[:task]
      assert response[:undo_by].starts_with?("remove_or_restore_task")
      assert response[:undo_by].include?('list: "Snoozed"')
    end
  end

  test "create_task_on_list fails when provided list does not exist" do
    input = {
      title: "Atlas Shrugged",
      list: "Books to Read"
    }
    stub_create_task_on_list(input) do
      error = assert_raises do
        @google_tasks.create_task_on_list(title_s: input[:title], list_s: input[:list])
        assert false, "It should have thrown an exception"
      end
      assert_equal "Unable to find a task list with the name '#{input[:list]}'", error.message
    end
  end

  test "remove_or_restore_task works to remove when given a task id" do
    stub_remove_task do
      response = @google_tasks.remove_or_restore_task(task_id_or_position_s: "mockid", is_deleted: true)

      assert response[:good_summary].starts_with?("Removed '#{task_data[:title]}'")
      assert response[:undo_by].starts_with?("remove_or_restore_task")
      assert response[:undo_by].include?('deleted: "false"')
    end
  end

  test "remove_or_restore_task works to remove when given a position" do
    stub_remove_task do
      response = @google_tasks.remove_or_restore_task(task_id_or_position_s: 1, is_deleted: true)
      assert response[:good_summary].starts_with?("Removed '#{task_data[:title]}'")
      assert_nil response[:task]
      #assert_task_equal task_data, response[:task]
      assert response[:undo_by].starts_with?("remove_or_restore_task")
      assert response[:undo_by].include?('deleted: "false"')
    end
  end

  test "remove_or_restore_task works to remove when given a position and typod list name and it's undo includes the list name" do
    stub_remove_task do
      response = @google_tasks.remove_or_restore_task(task_id_or_position_s: 1, is_deleted: true, list_s: "The Kids Projects")
      assert response[:good_summary].starts_with?("Removed '#{task_data[:title]}'")
      assert_nil response[:task]
      assert_equal 'remove_or_restore_task(task_id_or_position: "mockid", deleted: "false", list: "Kid Projects")', response[:undo_by]
    end
  end

  test "remove_or_restore_task works to restore when given a task id" do
    stub_restore_task do
      response = @google_tasks.remove_or_restore_task(task_id_or_position_s: "mockid", is_deleted: false)
      assert response[:good_summary].starts_with?("Restored '#{task_data[:title]}'")
    end
  end

  test "remove_or_restore_task errors when attempting to restore based on position" do
    stub_restore_task do
      error = assert_raises do
        @google_tasks.remove_or_restore_task(task_id_or_position_s: 1, is_deleted: false)
      end
      assert_equal "To restore you must call remove_or_restore_task with a task ID.", error.message
    end
  end

  test "remove_or_restore_task errors when attempting to remove an already deleted task and vice-versa" do
    stub_remove_task do
      error = assert_raises do
        @google_tasks.remove_or_restore_task(task_id_or_position_s: "mockid", is_deleted: false)
      end
      assert_equal "Task '#{task_data[:title]}' is already restored.", error.message
    end

    stub_restore_task do
      error = assert_raises do
        @google_tasks.remove_or_restore_task(task_id_or_position_s: "mockid", is_deleted: true)
      end
      assert_equal "Task '#{task_data[:title]}' is already deleted.", error.message
    end
  end

  test "change_task changes all fields and uses default list when not specified" do
    input = {
      id: "mockid",
      title: "changed title",
      notes: "changed note",
      completed: Time.current.strftime("%Y-%m-%dT00:00:00.000Z"),
    }
    stub_change_task(input) do
      response = @google_tasks.change_task(
        task_id_or_position_s: input[:id],
        title_s: input[:title],
        notes_s: input[:notes],
        due_date_s: input[:due],
        is_completed: !!input[:completed]
      )
      input[:list] = "My Tasks"
      assert_equal "Updated '#{input[:title]}'", response[:good_summary]
      assert_task_equal input, response[:task]
      assert response[:undo_by].starts_with?("change_task")
    end
  end

  test "change_task works with typod list name when specified" do
    input = {
      id: 1,
      title: "changed title",
      notes: "changed note",
      completed: Time.current.strftime("%Y-%m-%dT00:00:00.000Z"),
      list: "The Kids Projects"
    }
    stub_change_task(input) do
      response = @google_tasks.change_task(
        task_id_or_position_s: input[:id],
        title_s: input[:title],
        notes_s: input[:notes],
        due_date_s: input[:due],
        is_completed: !!input[:completed],
        list_s: input[:list],
      )
      input[:id] = "mockid"
      input[:list] = "Kid Projects"

      assert_equal "Updated '#{input[:title]}'", response[:good_summary]
      assert_task_equal input, response[:task]
      assert response[:undo_by].starts_with?("change_task")
    end
  end

  test "change_task moves to snoozed when due is set" do
    input = {
      id: "mockid",
      title: "changed title",
      notes: "changed note",
      due: 1.week.from_now.strftime("%Y-%m-%dT00:00:00.000Z"),
    }
    stub_change_task(input) do
      response = @google_tasks.change_task(
        task_id_or_position_s: input[:id],
        title_s: input[:title],
        notes_s: input[:notes],
        due_date_s: input[:due],
      )
      input[:list] = "Snoozed"
      assert_equal "Updated '#{input[:title]}'", response[:good_summary]
      assert_task_equal input, response[:task]
      assert response[:undo_by].starts_with?("change_task")
    end
  end

  test "change_task moves back to main when clearing due on a snoozed task" do
    input = {
      id: "mockid",
      title: "changed title",
      notes: "changed note",
      due: "clear",
      list: "Snoozed",
    }
    stub_change_task(input) do
      response = @google_tasks.change_task(
        task_id_or_position_s: input[:id],
        title_s: input[:title],
        notes_s: input[:notes],
        due_date_s: input[:due],
        list_s: input[:list],
      )
      input[:list] = "My Tasks"
      input[:due] = nil

      assert_equal "Updated '#{input[:title]}'", response[:good_summary]
      assert_task_equal input, response[:task]
      assert response[:undo_by].starts_with?("change_task")
    end
  end

  test "get_tasks returns tasks for the main list when nothing provoided" do
    stub_get_tasks do
      response = @google_tasks.get_tasks

      assert response[:good_summary].starts_with?("You have")
      assert response[:tasks].is_a?(Array)
      assert response[:undo_by].starts_with?("There is no")
    end
  end

  private

  def stub_create_task_on_list(hash, &block)
    stub_get_response(:get_lists, status: 200, response: lists_data) do
      stub_post_response(:create_task_for_list, status: 200, response: create_data(**hash.except(:list))) do
        Current.set(user: users(:keith)) do
          yield
        end
      end
    end
  end

  def stub_remove_task(&block)
    stub_get_response(:get_lists, status: 200, response: lists_data) do
      stub_get_response(:get_task_for_list_id, status: 200, response: task_data) do
        stub_get_response(:get_tasks_for_list, status: 200, response: tasks_data) do
          stub_delete_response(:delete_task, status: 204, response: task_data(deleted: true)) do
            Current.set(user: users(:keith)) do
              yield
            end
          end
        end
      end
    end
  end

  def stub_restore_task(&block)
    stub_get_response(:get_lists, status: 200, response: lists_data) do
      stub_get_response(:get_task_for_list_id, status: 200, response: task_data(deleted: true)) do
        stub_get_response(:get_tasks_for_list, status: 200, response: tasks_data(deleted: true)) do
          stub_patch_response(:update_task, status: 204, response: task_data(deleted: false)) do
            Current.set(user: users(:keith)) do
              yield
            end
          end
        end
      end
    end
  end

  def stub_change_task(hash, &block)
    stub_get_response(:get_lists, status: 200, response: lists_data) do
      stub_get_response(:get_task_for_list_id, status: 200, response: task_data) do
        stub_get_response(:get_tasks_for_list, status: 200, response: tasks_data) do
          stub_patch_response(:update_task, status: 200, response: task_data(**hash.except(:id, :deleted, :list))) do
            stub_delete_response(:delete_task, status: 204, response: task_data(deleted: true)) do
              stub_post_response(:create_task_for_list, status: 200, response: task_data(**hash.except(:id, :deleted, :list))) do
                Current.set(user: users(:keith)) do
                  yield
                end
              end
            end
          end
        end
      end
    end
  end

  def stub_get_tasks(&block)
    stub_get_response(:get_lists, status: 200, response: lists_data) do
      stub_get_response(:get_tasks_for_list, status: 200, response: tasks_data.merge(items: [])) do
        Current.set(user: users(:keith)) do
          yield
        end
      end
    end
  end

  def lists_data
    { items: [ {:kind=>"tasks#taskList",
        :id=>"mockMDUxNTI4Nzc2MjkxNjYxMDE4Nzc6MDow",
        :etag=>"\"NzQ4NTEwNzcw\"",
        :title=>"My Tasks",
        :updated=>"2024-06-18T18:30:29.507Z",
        :selfLink=>"https://www.googleapis.com/tasks/v1/users/@me/lists/MDUxNTI4Nzc2MjkxNjYxMDE4Nzc6MDow"},
      {:kind=>"tasks#taskList",
        :id=>"mockOXV5UExZdU5MeHhjQ1ljSg",
        :etag=>"\"NTg2MTQ5Nzkw\"",
        :title=>"To Read",
        :updated=>"2024-06-16T21:24:28.015Z",
        :selfLink=>"https://www.googleapis.com/tasks/v1/users/@me/lists/OXV5UExZdU5MeHhjQ1ljSg"},
      {:kind=>"tasks#taskList",
        :id=>"mockSjBhVUFfLWtEVElJRnJ2Yg",
        :etag=>"\"NzQ4OTY1Mjc4\"",
        :title=>"Kid Projects",
        :updated=>"2024-06-18T18:38:03.503Z",
        :selfLink=>"https://www.googleapis.com/tasks/v1/users/@me/lists/SjBhVUFfLWtEVElJRnJ2Yg"},
      {:kind=>"tasks#taskList",
        :id=>"mockdl9HUXZxYkp2R3FEaHg5QQ",
        :etag=>"\"NzQ4OTY1NTQx\"",
        :title=>"Snoozed",
        :updated=>"2024-06-18T18:38:04.054Z",
        :selfLink=>"https://www.googleapis.com/tasks/v1/users/@me/lists/dl9HUXZxYkp2R3FEaHg5QQ"}
    ]}
  end

  def task_data(title: "Title of task", notes: "notes for task", deleted: false, due: nil, completed: false)
    {
      id: "mockid",
      title: title,
      selfLink: "https://www.googleapis.com/tasks/v1/lists/SjBhVUFfLWtEVElJRnJ2Yg/tasks/NHhjQUY3bGlHVHdPUEwwaA",
      notes: notes,
      status: completed ? "completed" : "needsAction",
      completed: completed.presence && Time.zone.today.strftime("%Y-%m-%dT00:00:00.000Z"),
      due: due == "clear" ? nil : due,
      deleted: deleted,
      links: [],
      webViewLink: "https://tasks.google.com/task/4xcAF7liGTwOPL0h"
    }
  end

  def tasks_data(deleted: false)
    { items: [
      task_data(deleted: deleted).merge(position: "00001"),
      {
        id: "mockid2",
        position: "00002",
        title: "Title of task 2",
        selfLink: "https://www.googleapis.com/tasks/v1/lists/SjBhVUFfLWtEVElJRnJ2Yg/tasks/NHhjQUY3bGlHVHdPUEwwaA",
        status: "needsAction",
        due: nil,
        deleted: deleted,
        links: [],
        webViewLink: "https://tasks.google.com/task/4xcAF7liGTwOPL0h"
      },{
        id: "mockid3",
        position: "00003",
        title: "Title of task 3",
        selfLink: "https://www.googleapis.com/tasks/v1/lists/SjBhVUFfLWtEVElJRnJ2Yg/tasks/NHhjQUY3bGlHVHdPUEwwaA",
        status: "needsAction",
        due: nil,
        deleted: deleted,
        links: [],
        webViewLink: "https://tasks.google.com/task/4xcAF7liGTwOPL0h"
      }]
    }
  end

  def create_data(title:, notes: nil, due: nil)
    { kind: "tasks#task",
      id: "mockid",
      etag: "\"NzU5Mjc2NTA2\"",
      title: title,
      updated: "2024-06-18T21:29:54.000Z",
      selfLink: "https://www.googleapis.com/tasks/v1/lists/SjBhVUFfLWtEVElJRnJ2Yg/tasks/NHhjQUY3bGlHVHdPUEwwaA",
      position: "00000000000000000000",
      notes: notes,
      status: "needsAction",
      due: due,
      links: [],
      webViewLink: "https://tasks.google.com/task/4xcAF7liGTwOPL0h"
    }.compact
  end

  def assert_task_equal(input, task)
    assert task[:id].present?
    assert_equal input[:title], task[:title]

    assert_nil task[:notes]                  if input[:notes].nil?
    assert_equal input[:notes], task[:notes] if input[:notes].present?
    assert_nil task[:due]                if input[:due].nil?
    assert_equal input[:due], task[:due] if input[:due].present?
    assert_equal "My Tasks", task[:list]   if input[:list].nil?
    assert_equal input[:list], task[:list] if input[:list].present?

    assert_equal "completed", task[:status]   if input[:completed].present?
    assert_equal "needsAction", task[:status] if input[:completed].nil?
  end
end
