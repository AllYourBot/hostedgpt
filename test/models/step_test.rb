require "test_helper"

class StepTest < ActiveSupport::TestCase
  test "has an associated assistant" do
    assert_instance_of Assistant, steps(:hear_me_response).assistant
  end

  test "has an associated conversation" do
    assert_instance_of Conversation, steps(:hear_me_response).conversation
  end

  test "has an associated run" do
    assert_instance_of Run, steps(:hear_me_response).run
  end

  test "simple create works" do
    assert_nothing_raised do
      Step.create!(
        assistant: assistants(:samantha),
        conversation: conversations(:greeting),
        run: runs(:hear_me_response),
        kind: 'message_creation',
        status: 'in_progress',
        details: {}
      )
    end
  end

  test "associations are deleted upon destroy" do
    assert_nothing_raised do
      steps(:hear_me_response).destroy!
    end
  end
end
