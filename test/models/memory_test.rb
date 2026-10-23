require "test_helper"

class MemoryTest < ActiveSupport::TestCase
  # Association tests

  test "has an associated user" do
    assert_instance_of User, memories(:location).user
  end

  test "has associated message" do
    assert_instance_of Message, memories(:location).message
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
  end
end
