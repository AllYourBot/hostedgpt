require "test_helper"

class Toolbox::GoogleTasksTest < ActiveSupport::TestCase
  setup do
    @google_tasks = Toolbox::GoogleTasks.new
  end

  test "create_task_on_list creates when called with just title" do
    input = {
      title: "do this"
    }
    stub_create_task_on_list(**input) do
      response = @google_tasks.create_task_on_list(title_s: input[:title])
      assert_equal input[:title], response[:task_title]
      assert_nil response[:task_notes]
      assert_nil response[:task_due]
      assert_equal "My Tasks", response[:list]
      assert response[:good_summary].length > 10
    end
  end

  test "create_task_on_list creates a task with title, notes, due, and list" do
    input = {
      title: "do this",
      notes: "a note",
      due: "2024-5-1T00:00:00.000Z",
      list: "Snoozed",
    }
    stub_create_task_on_list(**input) do
      response = @google_tasks.create_task_on_list(
        title_s: input[:title],
        notes_s: input[:note],
        due_date_s: input[:due],
        list_s: input[:list]
      )
      assert_equal input[:title], response[:task_title]
      assert_equal input[:notes], response[:task_notes]
      assert_equal input[:due], response[:task_due]
      assert_equal input[:list], response[:list]
      assert response[:good_summary].length > 10
    end
  end

  test "create_task_on_list succeeds when small typo in list name" do
    input = {
      title: "do this",
      list: "My Task List"
    }
    stub_create_task_on_list(**input) do
      response = @google_tasks.create_task_on_list(title_s: input[:title], list_s: input[:list])
      assert_equal input[:title], response[:task_title]
      assert_nil response[:task_notes]
      assert_nil response[:task_due]
      assert_equal "My Tasks", response[:list]
      assert response[:good_summary].length > 10
    end
  end

  test "create_task_on_list fails when provided list does not exist" do
    input = {
      title: "Atlas Shrugged",
      list: "Books to Read"
    }
    stub_create_task_on_list(**input) do
      begin
        @google_tasks.create_task_on_list(title_s: input[:title], list_s: input[:list])
        assert false, "It should have thrown an exception"
      rescue => e
        assert_equal "Unable to find a task list with the name '#{input[:list]}'", e.message
      end
    end
  end

  private

  def stub_create_task_on_list(hash, &block)
    stub_get_response(:get_lists, status: 200, **lists_data) do
      stub_post_response(:create_task_for, status: 200, **create_data(**hash.except(:list))) do
        Current.set(user: users(:keith)) do
          yield
        end
      end
    end
  end

  def lists_data
    { items: [ {:kind=>"tasks#taskList",
        :id=>"MDUxNTI4Nzc2MjkxNjYxMDE4Nzc6MDow",
        :etag=>"\"NzQ4NTEwNzcw\"",
        :title=>"My Tasks",
        :updated=>"2024-06-18T18:30:29.507Z",
        :selfLink=>"https://www.googleapis.com/tasks/v1/users/@me/lists/MDUxNTI4Nzc2MjkxNjYxMDE4Nzc6MDow"},
      {:kind=>"tasks#taskList",
        :id=>"OXV5UExZdU5MeHhjQ1ljSg",
        :etag=>"\"NTg2MTQ5Nzkw\"",
        :title=>"To Read (longer)",
        :updated=>"2024-06-16T21:24:28.015Z",
        :selfLink=>"https://www.googleapis.com/tasks/v1/users/@me/lists/OXV5UExZdU5MeHhjQ1ljSg"},
      {:kind=>"tasks#taskList",
        :id=>"SjBhVUFfLWtEVElJRnJ2Yg",
        :etag=>"\"NzQ4OTY1Mjc4\"",
        :title=>"Do Kid Projects",
        :updated=>"2024-06-18T18:38:03.503Z",
        :selfLink=>"https://www.googleapis.com/tasks/v1/users/@me/lists/SjBhVUFfLWtEVElJRnJ2Yg"},
      {:kind=>"tasks#taskList",
        :id=>"dl9HUXZxYkp2R3FEaHg5QQ",
        :etag=>"\"NzQ4OTY1NTQx\"",
        :title=>"Snoozed",
        :updated=>"2024-06-18T18:38:04.054Z",
        :selfLink=>"https://www.googleapis.com/tasks/v1/users/@me/lists/dl9HUXZxYkp2R3FEaHg5QQ"}
    ]}
  end

  def create_data(title:, notes: nil, due: nil)
    { "kind"=>"tasks#task",
      "id"=>"dummyid",
      "etag"=>"\"NzU5Mjc2NTA2\"",
      "title"=> title,
      "updated"=>"2024-06-18T21:29:54.000Z",
      "selfLink"=>"https://www.googleapis.com/tasks/v1/lists/SjBhVUFfLWtEVElJRnJ2Yg/tasks/NHhjQUY3bGlHVHdPUEwwaA",
      "position"=>"00000000000000000000",
      "notes"=> notes,
      "status"=>"needsAction",
      "due"=> due,
      "links"=>[],
      "webViewLink"=>"https://tasks.google.com/task/4xcAF7liGTwOPL0h"
    }.compact
  end
end
