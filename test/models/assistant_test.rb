require "test_helper"

class AssistantTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, assistants(:samantha).user
  end

  test "has associated conversations" do
    assert_instance_of Conversation, assistants(:samantha).conversations.first
  end

  test "has associated messages (through conversations)" do
    assert_instance_of Message, assistants(:samantha).messages.first
  end

  test "has associated documents" do
    assert_instance_of Document, assistants(:samantha).documents.first
  end

  test "has associated runs" do
    assert_instance_of Run, assistants(:samantha).runs.first
  end

  test "has associated steps" do
    assert_instance_of Step, assistants(:samantha).steps.first
  end

  test "tools is an array of objects" do
    assert_instance_of Array, assistants(:samantha).tools
  end

  test "simple create works" do
    assert_nothing_raised do
      Assistant.create!(user: users(:keith))
    end
  end

  test "tools defaults to empty array on create" do
    a = Assistant.create!(user: users(:keith))
    assert_equal [], a.tools
  end

  test "associations are deleted upon destroy" do
    assistant = assistants(:samantha)
    conversation_count = assistant.conversations.count * -1
    document_count = assistant.documents.count * -1
    run_count = assistant.runs.count * -1
    step_count = assistant.steps.count * -1

    assert_difference "Conversation.count", conversation_count do
      assert_difference "Document.count", document_count do
        assert_difference "Run.count", run_count do
          assert_difference "Step.count", step_count do
            assistant.destroy
          end
        end
      end
    end
  end
end
