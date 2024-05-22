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
      Assistant.create!(user: users(:keith), language_model: language_models(:gpt_4), name: 'abc')
    end
  end

  test "tools defaults to empty array on create" do
    a = Assistant.create!(user: users(:keith), language_model: language_models(:gpt_4), name: 'abc')
    assert_equal [], a.tools
  end

  test "associations are deleted when user is being destroyed" do
    User.stub_any_instance(:destroy_in_progress?, true) do
      assert_difference "Conversation.count", -6 do
        assert_difference "Document.count", -5 do
          assert_difference "Run.count", -19 do
            assert_difference "Step.count", -3 do
              assistants(:samantha).destroy
            end
          end
        end
      end
    end
  end

  test "associations are not deleted upon destroy" do
    assert_no_difference "Conversation.count" do
      assert_no_difference "Document.count" do
        assert_no_difference "Run.count" do
          assert_no_difference "Step.count" do
            assistants(:samantha).destroy
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
    assert_equal "G4", assistants(:keith_gpt4).initials
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

  test "cannot destroy last assistant of a user" do
    assert_raise do
      users(:rob).assistants.first.destroy
    end
  end
  test "can destroy assistant of a user if they have more than one" do
    assert_nothing_raised do
      users(:keith).assistants.first.destroy
    end
  end
end
