require "test_helper"

class ToolboxTest < ActiveSupport::TestCase
  test "tools" do
    assert_equal 2, Toolbox.tools.length
    assert Toolbox::OpenMeteo.tools.first[:function].values.all? { |value| value.present? }
    assert Toolbox::OpenMeteo.tools.first[:function][:description].length > 100
  end

  test "call" do
    assert_equal "Hello, World!", Toolbox.call("helloworld_hi", { name: "World" })
  end
end
