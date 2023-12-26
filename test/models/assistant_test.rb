require "test_helper"

class AssistantTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, assistants(:samantha).user
  end

  test "has associated conversations" do
    assert_instance_of Conversation, assistants(:samantha).conversations.first
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
    assert_difference "Conversation.count", -1 do
      assert_difference "Document.count", -2 do
        assert_difference "Run.count", -2 do
          assert_difference "Step.count", -2 do
            assistants(:samantha).destroy
          end
        end
      end
    end
  end
end
