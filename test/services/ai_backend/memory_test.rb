require "test_helper"

class AIBackend::MemoryTest < ActiveSupport::TestCase
  setup do
    @asst_instructions = assistants(:samantha).instructions
  end

  test "full_instructions simply shows date & time when nothing is provided" do
    users(:keith).memories.delete_all
    assistants(:samantha).update!(instructions: nil)

    backend = AIBackend.new(
      users(:keith),
      messages(:hear_me).assistant,
      messages(:hear_me).conversation,
      messages(:hear_me)
    )

    instructions = backend.send(:full_instructions)
    assert instructions.starts_with?("For the user, the current time")
    refute instructions.include?("remembered")
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

  test "full_instructions INCLUDES the assistant's context files after memories" do
    file = Rack::Test::UploadedFile.new(file_fixture("test_document.txt"), "text/plain")
    assistants(:samantha).documents.create!(file: file)

    backend = AIBackend.new(
      users(:keith),
      messages(:hear_me).assistant,
      messages(:hear_me).conversation,
      messages(:hear_me)
    )
    full_instructions = backend.send(:full_instructions)
    assert_includes full_instructions, %|<file name="test_document.txt">|
    assert_includes full_instructions, "This is a text document"
    assert full_instructions.index("remembered") < full_instructions.index("<file"), "context should follow memories"
    assert full_instructions.index("<file") < full_instructions.index("current time"), "context should precede the date"
  end
end
