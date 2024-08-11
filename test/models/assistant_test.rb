require "test_helper"

class AssistantTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, assistants(:samantha).user
  end

  test "has associated conversations" do
    assert_instance_of Conversation, assistants(:samantha).conversations.first
  end

  test "has supports_images?" do
    assert assistants(:samantha).supports_images?
    refute assistants(:keith_gpt3).supports_images?
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

  test "has associated messages (through conversations)" do
    assert_instance_of Message, assistants(:samantha).messages.first
  end

  test "has associated language_model" do
    assert_instance_of LanguageModel, assistants(:samantha).language_model
  end

  test "tools is an array of objects" do
    assert_instance_of Array, assistants(:samantha).tools
  end

  test "simple create works and tool defaults to empty array" do
    a = nil
    assert_nothing_raised do
      a = Assistant.create!(
        user: users(:keith),
        language_model: language_models(:gpt_4o),
        name: 'abc'
      )
    end
  end

  test "assert execption occures when external ids are not unique" do
    Assistant.create!(user: users(:keith), language_model: language_models(:gpt_4o), name: "new", external_id: "1")
    assert_raise ActiveRecord::RecordNotUnique do
      Assistant.create!(user: users(:rob), language_model: language_models(:gpt_4o), name: "new", external_id: "1")
    end
  end

  test "associations are deleted upon destroy" do
    assistant = assistants(:samantha)
    conversation_count = assistant.conversations.count * -1
    message_count = assistant.conversations.map { |c| c.messages.length }.sum * -1
    document_count = (assistant.documents.count+assistant.conversations.sum { |c| c.messages.sum { |m| m.documents.count }}) * -1
    run_count = assistant.runs.count * -1
    step_count = assistant.steps.count * -1

    assert_difference "Message.count", message_count do
      assert_difference "Conversation.count", conversation_count do
        assert_difference "Document.count", document_count do
          assert_difference "Run.count", run_count do
            assert_difference "Step.count", step_count do
              assistant.destroy!
            end
          end
        end
      end
    end
  end

  test "associations are left intact upon soft delete" do
    assistant = assistants(:samantha)

    assert_no_difference "Message.count" do
      assert_no_difference "Conversation.count" do
        assert_no_difference "Document.count" do
          assert_no_difference "Run.count" do
            assert_no_difference "Step.count" do
              assistant.deleted!
            end
          end
        end
      end
    end
    refute_nil assistant.deleted_at
  end

  test "associations are not deleted upon soft delete" do
    assert_no_difference "Message.count" do
      assert_no_difference "Conversation.count" do
        assert_no_difference "Document.count" do
          assert_no_difference "Run.count" do
            assert_no_difference "Step.count" do
              assistants(:samantha).deleted!
            end
          end
        end
      end
    end
  end

  test "initials returns a single letter" do
    assert_equal "S", assistants(:samantha).initials
  end

  test "initials returns a single two letters for two-word names" do
    assistants(:samantha).update!(name: "Samantha Jones")
    assert_equal "SJ", assistants(:samantha).initials
  end

  test "initials will split on - and return two characters" do
    assert_equal "G4", assistants(:rob_gpt4).initials
  end

  test "language model validated" do
    record = Assistant.new
    refute record.valid?
    assert record.errors[:language_model].present?
  end

  test "name validated" do
    record = Assistant.new
    refute record.valid?
    assert record.errors[:name].present?
  end
end
