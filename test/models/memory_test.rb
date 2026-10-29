require "test_helper"

class MemoryTest < ActiveSupport::TestCase
  # Association tests

  test "has an associated user" do
    assert_instance_of User, memories(:location).user
  end

  test "has associated message" do
    assert_instance_of Message, memories(:location).message
  end

  test "has an associated assistant" do
    assert_instance_of Assistant, memories(:haiku).assistant
  end

  test "for_assistant INCLUDES the shared memories and the ones saved for that assistant" do
    remembered = users(:keith).memories.for_assistant(assistants(:keith_gpt3))
    assert_equal [memories(:haiku), memories(:location), memories(:pet)].sort, remembered.sort, "The assistant should get its own memory along with the shared ones"
  end

  test "for_assistant EXCLUDES the memories saved for another assistant" do
    remembered = users(:keith).memories.for_assistant(assistants(:samantha))
    assert_equal [memories(:location), memories(:pet)].sort, remembered.sort, "The assistant should only get the shared memories"
  end

  # Creation tests

  test "create with minimal possible attributes" do
    assert_nothing_raised do
      Memory.create!(user: users(:keith), detail: "He prefers metric units")
    end
  end

  test "new enforces all required attributes" do
    memory = Memory.new
    refute memory.valid?, "A memory without a user or detail should be invalid"
    assert_equal ["must exist"], memory.errors[:user]
    assert_equal ["can't be blank"], memory.errors[:detail]
    assert_empty memory.errors[:message], "A memory should not require a source message"
    assert_empty memory.errors[:assistant], "A memory should not require an assistant"

    memory = Memory.new(user: users(:keith), assistant: assistants(:rob_gpt4), detail: "He prefers metric units")
    refute memory.valid?, "A memory should not be saved for someone else's assistant"
    assert_equal ["is invalid"], memory.errors[:assistant], "The assistant should belong to the memory's user"
  end

  test "create with an assistant" do
    memory = Memory.create!(user: users(:keith), assistant: assistants(:keith_gpt3), detail: "He wants answers in under three lines")
    assert_equal assistants(:keith_gpt3), memory.assistant, "The memory should be saved for just that assistant"
  end
end
