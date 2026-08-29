require "test_helper"

class AssistantTest < ActiveSupport::TestCase
  test "initials" do
    samantha = assistants(:samantha)
    assert_equal "S", samantha.initials

    keith_gpt4 = assistants(:keith_gpt4)
    assert_equal "OG", keith_gpt4.initials

    keith_gpt3 = assistants(:keith_gpt3)
    assert_equal "G3", keith_gpt3.initials
  end

  test "logo_filename reflects the underlying language model's api_service, not the assistant's own name" do
    samantha = assistants(:samantha) # named "Samantha", but backed by gpt_4o
    assert_equal "openai_logo.svg", samantha.logo_filename
  end

  test "to_s" do
    samantha = assistants(:samantha)
    assert_equal "Samantha", samantha.to_s
  end

  test "ordered sorts by position" do
    keith = users(:keith)
    keith.assistants.reposition(keith.assistants.pluck(:id).shuffle)

    assert_equal keith.assistants.order(:position).pluck(:id), keith.assistants.ordered.pluck(:id)
  end

  test "reposition renumbers to match the order of the ids it is given" do
    keith = users(:keith)
    ids = keith.assistants.ordered.pluck(:id).rotate

    keith.assistants.reposition(ids.map(&:to_s)) # the ids arrive from the browser as strings

    assert_equal ids, keith.assistants.ordered.pluck(:id)
    assert_equal (0...ids.length).to_a, keith.assistants.ordered.pluck(:position)
  end

  test "reposition ignores assistants outside the collection it is called on" do
    keith = users(:keith)
    rob_assistant = assistants(:rob_gpt4)

    keith.assistants.reposition([rob_assistant.id] + keith.assistants.ordered.pluck(:id))

    assert_nil rob_assistant.reload.position
  end

  test "a new assistant goes to the top of the list" do
    keith = users(:keith)
    keith.assistants.reposition(keith.assistants.ordered.pluck(:id))

    assistant = keith.assistants.create!(name: "Newcomer", language_model: language_models(:gpt_4o))

    assert_equal assistant, keith.assistants.ordered.first
  end

  test "language_model_api_name=" do
    assistant = assistants(:samantha)
    assistant.language_model_api_name = "gpt-4o"
    assert_equal language_models(:gpt_4o), assistant.language_model
  end
end
