require "test_helper"

class RunTest < ActiveSupport::TestCase
  test "has an associated assistant" do
    assert_instance_of Assistant, runs(:hear_me_response).assistant
  end

  test "has an associated conversation" do
    assert_instance_of Conversation, runs(:hear_me_response).conversation
  end

  test "has associated steps" do
    assert_instance_of Step, runs(:hear_me_response).steps.first
  end

  test "has an associated message" do
    assert_instance_of Message, runs(:identify_photo_response).message
  end

  test "simple create works" do
    assert_nothing_raised do
      Run.create!(
        assistant: assistants(:samantha),
        conversation: conversations(:greeting),
        instructions: assistants(:samantha).instructions,
        status: "queued",
        expired_at: 1.minute.from_now
      )
    end
  end

  test "model populated from assistant" do
      r = Run.create!(
        assistant: assistants(:keith_claude3),
        conversation: conversations(:greeting),
        instructions: "Some instructions",
        status: "queued",
        expired_at: 1.minute.from_now
      )
      assert_equal 'claude-3-opus-20240229', r.model
  end

  test "associations are deleted upon destroy" do
    assert_difference "Step.count", -1 do
      runs(:hear_me_response).destroy
    end
  end
end
