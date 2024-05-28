require "test_helper"

class ToolboxTest < ActiveSupport::TestCase
  test "tools returns information on all the tools" do
    assert_equal 4, Toolbox.tools.length
    assert Toolbox::OpenMeteo.tools.first[:function].values.all? { |value| value.present? }
    assert Toolbox::OpenMeteo.tools.first[:function][:description].length > 100
  end

  test "describe directive within a tool sets the function description" do
    tool = Toolbox::HelloWorld.tools.find { |t| t[:function][:name] == "helloworld_hi" }
    assert_equal "This is a description for hi", tool.dig(:function, :description)
  end

  test "tools get a default description if describe is not used" do
    tool = Toolbox::HelloWorld.tools.find { |t| t[:function][:name] == "helloworld_get_eligibility" }
    assert_equal "Get eligibility given birthdate and gender", tool.dig(:function, :description)
  end

  test "call executes a tool" do
    assert_equal "Hello, World!", Toolbox.call("helloworld_hi", { name: "World" })
  end
end
