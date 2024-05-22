require "test_helper"

class ToolboxTest < ActiveSupport::TestCase
  test "tools" do
    assert_equal 1, Toolbox.tools.length
    assert OpenMeteo.tools.first[:function].values.all? { |value| value.present? }
    assert OpenMeteo.tools.first[:function][:description].length > 100
  end
end
