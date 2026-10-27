require "test_helper"

class Settings::MemoriesControllerTest < ActionDispatch::IntegrationTest
  test "should get index WITH NO memories" do
    login_as users(:rob)
    get settings_memories_url
    assert_response :success
    assert_match "No memories", response.body
    assert_no_match "Clear All Memories", response.body
  end

  test "should get index WITH memories" do
    login_as users(:keith)
    get settings_memories_url
    assert_response :success
    assert_no_match "No memories", response.body
    assert_match "Austin, Texas", response.body
    assert_match "Clear All Memories", response.body
    assert_select "form[action=?][method=post] input[name=?]", settings_memories_path, "memory[detail]"
    assert_select "select[name=?] option", "memory[assistant_id]", users(:keith).assistants.count + 1, "Every assistant should be offered along with all assistants"
    assert_contains_text "#memory_#{memories(:haiku).id}", assistants(:keith_gpt3).name
    assert_contains_text "#memory_#{memories(:location).id}", "All assistants"
  end

  test "should get index WITH a memory that HAS NO source message" do
    users(:keith).memories.create!(detail: "He prefers metric units")
    login_as users(:keith)
    get settings_memories_url
    assert_response :success
    assert_contains_text "#memories", "He prefers metric units"
    assert_select "#memories a", users(:keith).memories.where.not(message: nil).count, "Only memories with a source message should link to it"
  end

  test "should create memory" do
    login_as users(:keith)
    assert_difference "Memory.count", 1 do
      post settings_memories_url, params: { memory: { detail: "He prefers metric units" } }
    end

    assert_redirected_to settings_memories_url
    assert flash[:notice].present?, "There should be a flash notice"

    memory = Memory.last
    assert_equal users(:keith), memory.user, "The memory should belong to the current user"
    assert_equal "He prefers metric units", memory.detail, "The memory should store the submitted detail"
    assert_nil memory.message, "A manually added memory should not have a source message"
  end

  test "should create memory FOR ONE assistant" do
    login_as users(:keith)
    assert_difference "Memory.count", 1 do
      post settings_memories_url, params: { memory: { detail: "He wants answers in under three lines", assistant_id: assistants(:keith_gpt3).id } }
    end

    assert_redirected_to settings_memories_url
    assert_equal assistants(:keith_gpt3), Memory.last.assistant, "The memory should be saved for the chosen assistant"
  end

  test "should not create memory FOR ANOTHER USER'S assistant" do
    login_as users(:keith)
    assert_no_difference "Memory.count" do
      post settings_memories_url, params: { memory: { detail: "He wants answers in under three lines", assistant_id: assistants(:rob_gpt4).id } }
    end

    assert_response :unprocessable_content
    assert_select "#error_explanation", 1, "The form should show the validation error"
  end

  test "should not create memory WITH a blank detail" do
    login_as users(:keith)
    assert_no_difference "Memory.count" do
      post settings_memories_url, params: { memory: { detail: " " } }
    end

    assert_response :unprocessable_content
    assert_select "#error_explanation", 1, "The form should show the validation error"
    assert_contains_text "#memories", "Austin, Texas"
  end

  test "delete all the user's memories" do
    login_as users(:keith)
    assert_difference "Memory.count", -users(:keith).memories.count do
      delete settings_memories_url
    end

    assert_redirected_to settings_memories_url
    assert flash[:notice].present?
  end

  test "delete a single user's memory" do
    login_as users(:keith)
    assert_difference "Memory.count", -1 do
      delete settings_memory_url(memories(:pet))
    end

    assert_redirected_to settings_memories_url
    assert flash[:notice].present?
  end
end
