require "test_helper"

class AIBackend::MemoryTest < ActiveSupport::TestCase
  setup do
    @asst_instructions = assistants(:samantha).instructions
  end

  test "full_instructions is nil when nothing is provided" do
    users(:keith).memories.delete_all
    assistants(:samantha).update!(instructions: nil)

    backend = AIBackend.new(
      users(:keith),
      messages(:hear_me).assistant,
      messages(:hear_me).conversation,
      messages(:hear_me)
    )

    assert_nil backend.send(:full_instructions)
  end

  test "full_instructions INCLUDES memories and DOES INCLUDE assistant instructions when both are provided" do

    backend = AIBackend.new(
      users(:keith),
      messages(:hear_me).assistant,
      messages(:hear_me).conversation,
      messages(:hear_me)
    )
    full_instructions = backend.send(:full_instructions)
    assert full_instructions.include? @asst_instructions
    assert full_instructions.include? "been told and remembered"
    assert full_instructions.include? "Austin, Texas"
  end

  test "full_instructions INCLUDES memories but does NOT INCLUDE assistant instructions" do
    assistants(:samantha).update!(instructions: nil)

    backend = AIBackend.new(
      users(:keith),
      messages(:hear_me).assistant,
      messages(:hear_me).conversation,
      messages(:hear_me)
    )
    full_instructions = backend.send(:full_instructions)
    refute full_instructions.include? @asst_instructions
    assert full_instructions.include? "been told and remembered"
    assert full_instructions.include? "Austin, Texas"
  end

  test "full_instructions does NOT INCLUDE memories but DOES INCLUDE assistant instructions" do
    users(:keith).memories.delete_all

    backend = AIBackend.new(
      users(:keith),
      messages(:hear_me).assistant,
      messages(:hear_me).conversation,
      messages(:hear_me)
    )
    full_instructions = backend.send(:full_instructions)
    assert full_instructions.include? @asst_instructions
    refute full_instructions.include? "been told and remembered"
    refute full_instructions.include? "Austin, Texas"
  end
end
