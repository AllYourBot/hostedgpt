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

  test "ask_user REFUSES a blank question" do
    error = assert_raises(ArgumentError, "A blank question has nothing to show the user") do
      Toolbox::AskUser.new.ask_user(question_s: " ", choices_a: ["A"])
    end
    assert_includes error.message, "question", "The model should be told what was missing"
  end

  test "ask_user reads choices sent as a JSON STRING" do
    assert_equal ["A", "B"], Toolbox::AskUser.new.ask_user(question_s: "Which?", choices_a: '["A","B"]')[:choices], "A stringified list should still become separate buttons"
  end
end
