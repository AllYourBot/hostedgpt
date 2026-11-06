require "test_helper"

class Toolbox::RubyLLMToolTest < ActiveSupport::TestCase
  test "ruby_llm_tools expose the SAME names, descriptions and schemas as Toolbox.tools" do
    expected = Toolbox.tools.map { [it.dig(:function, :name), it.dig(:function, :description), it.dig(:function, :parameters).deep_stringify_keys] }
    actual = Toolbox.ruby_llm_tools.map { [it.name, it.description, it.parameters_schema.deep_stringify_keys] }

    assert_equal expected, actual, "The model should see exactly the tools it saw before the move to RubyLLM tools"
    assert Toolbox.ruby_llm_tools.all? { it.is_a?(::RubyLLM::Tool) }, "Each tool should be a real RubyLLM::Tool"
  end

  test "call RUNS the Toolbox method and returns its result as JSON" do
    assert_equal "\"Hello, World!\"", hello_tool.call(name: "World"), "The Toolbox method should run with mapped parameters"
  end

  test "call DROPS hallucinated arguments" do
    assert_equal "\"Hello, World!\"", hello_tool.call(name: "World", bogus: 1), "An argument the method doesn't take should be ignored"
  end

  test "call returns the friendly error text when the Toolbox method RAISES" do
    tool = Toolbox.ruby_llm_tools.find { it.name == "helloworld_get_eligibility" }

    result = tool.call(birthdate: "2000-01-01", gender: "male")

    assert result.start_with?('"An unexpected error occurred (Pretend this call failed'), "The model should be told the tool failed, not crash the job"
    assert_includes result, "DO NOT MAKE ANY GUESSES", "The model should be told not to guess"
  end

  private

  def hello_tool = Toolbox.ruby_llm_tools.find { it.name == "helloworld_hi" }
end
