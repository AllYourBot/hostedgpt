require "test_helper"

class ToolboxTest < ActiveSupport::TestCase
  test "tools" do
    assert_equal 5, Toolbox.tools.length
    assert Toolbox::OpenMeteo.tools.first[:function].values.all? { |value| value.present? }
    assert Toolbox::OpenMeteo.tools.first[:function][:description].length > 100
    tools = [
      {:type=>"function", :function=>{:name=>"helloworld_bad", :description=>"Bad given ", :parameters=>{:type=>"object", :properties=>{}, :required=>[]}}},
      {:type=>"function", :function=>{:name=>"helloworld_hi", :description=>"Hi given name_s", :parameters=>{:type=>"object", :properties=>{"name"=>{:type=>"string"}}, :required=>["name"]}}}
    ]
    assert_equal tools, Toolbox::HelloWorld.tools.sort { |a,b| a[:function][:name] <=> b[:function][:name] }
  end

  test "call" do
    assert_equal "Hello, World!", Toolbox.call("helloworld_hi", { name: "World" })
  end
end
