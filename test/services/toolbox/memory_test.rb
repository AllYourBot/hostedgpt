require "test_helper"

class Toolbox::MemoryTest < ActiveSupport::TestCase
  setup do
    @memory = Toolbox::Memory.new
  end

  test "remember_detail_about_user creates a new memory with Current set" do
    assert_difference "Memory.count", 1 do
      Current.set(user: users(:keith), message: messages(:photo_identified)) do
        @memory.remember_detail_about_user(detail_s: "Keith owns a cat")
      end
    end

    new_memory = Memory.last
    assert_equal users(:keith), new_memory.user
    assert_equal messages(:identify_photo), new_memory.message
    assert_nil new_memory.assistant, "The memory should be shared with all assistants"
  end

  test "remember_detail_about_user saves the memory for just the replying assistant when ONLY FOR THIS ASSISTANT" do
    Current.set(user: users(:keith), message: messages(:photo_identified)) do
      @memory.remember_detail_about_user(detail_s: "Keith wants photos described in one line", is_only_for_this_assistant: true)
    end

    assert_equal messages(:photo_identified).assistant, Memory.last.assistant, "The memory should belong to the assistant that saved it"
  end

  test "remember_detail_about_user accepts only_for_this_assistant AS A STRING" do
    Current.set(user: users(:keith), message: messages(:photo_identified)) do
      @memory.remember_detail_about_user(detail_s: "Keith wants photos described in one line", is_only_for_this_assistant: "false")
    end

    assert_nil Memory.last.assistant, "A model that sends the boolean as a string should still get a shared memory"
  end

  test "tools exposes only_for_this_assistant as an optional boolean" do
    parameters = Toolbox::Memory.tools.first.dig(:function, :parameters)
    assert_equal({ type: "boolean" }, parameters.dig(:properties, "only_for_this_assistant"), "The model should see a boolean argument")
    assert_equal ["detail"], parameters[:required], "The model should only be required to send the detail"
  end

  test "remember_detail_about_user DOES NOT creates a new memory without Current" do
    assert_no_difference "Memory.count" do
      assert_raises do
        @memory.remember_detail_about_user(detail_s: "Keith owns a cat")
      end
    end
  end
end
