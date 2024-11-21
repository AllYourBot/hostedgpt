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
