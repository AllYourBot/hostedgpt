require "test_helper"

class AIBackendTest < ActiveSupport::TestCase
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

  test "full_instructions INCLUDES memories but does NOT INCLUDE assistant instructions" do
    old_instructions = assistants(:samantha).instructions
    assistants(:samantha).update!(instructions: nil)

    backend = AIBackend.new(
      users(:keith),
      messages(:hear_me).assistant,
      messages(:hear_me).conversation,
      messages(:hear_me)
    )

    refute backend.send(:full_instructions).include? old_instructions
    assert backend.send(:full_instructions).include? "Austin, Texas"
  end

  test "full_instructions does NOT INCLUDE memories but DOES INCLUDE assistant instructions" do
    users(:keith).memories.delete_all

    backend = AIBackend.new(
      users(:keith),
      messages(:hear_me).assistant,
      messages(:hear_me).conversation,
      messages(:hear_me)
    )

    assert_equal assistants(:samantha).instructions, backend.send(:full_instructions)
    refute backend.send(:full_instructions).include? "Austin, Texas"
  end
end
