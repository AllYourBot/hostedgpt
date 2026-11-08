require "test_helper"

class Toolbox::AskUserTest < ActiveSupport::TestCase
  test "ask_user returns the question and the choices" do
    assert_equal(
      { message_to_user: "Which?", choices: ["A", "B"] },
      Toolbox::AskUser.new.ask_user(question_s: "Which?", choices_a: ["A", "B"]),
      "The question should be shown with its choices"
    )
  end

  test "ask_user DROPS blank and duplicate choices" do
    result = Toolbox::AskUser.new.ask_user(question_s: "Which?", choices_a: [" A ", "", "A", nil, "B"])

    assert_equal ["A", "B"], result[:choices], "Blank and repeated choices should not become buttons"
  end

  test "ask_user works WITHOUT choices" do
    assert_equal [], Toolbox::AskUser.new.ask_user(question_s: "Which?")[:choices], "A question alone should still be asked"
  end

  test "Toolbox.call routes askuser_ask_user and maps choices" do
    assert_equal(
      { message_to_user: "Q", choices: ["x"] },
      Toolbox.call("askuser_ask_user", { "question" => "Q", "choices" => ["x"] }),
      "The model's question and choices arguments should reach the method"
    )
  end
end
