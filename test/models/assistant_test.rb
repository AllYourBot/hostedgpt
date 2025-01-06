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

  test "to_s" do
    samantha = assistants(:samantha)
    assert_equal "Samantha", samantha.to_s
  end

  test "language_model_api_name=" do
    assistant = assistants(:samantha)
    assistant.language_model_api_name = "gpt-4o"
    assert_equal language_models(:gpt_4o), assistant.language_model
  end
end
