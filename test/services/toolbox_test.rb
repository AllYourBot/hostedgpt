require "test_helper"

class ToolboxTest < ActiveSupport::TestCase
  test "tools returns information on all the tools" do
    assert Toolbox.tools.length > 2
    assert Toolbox::OpenMeteo.tools.first[:function].values.all? { |value| value.present? }
    assert Toolbox::OpenMeteo.tools.first[:function][:description].length > 100
  end

  test "tools includes gmail if enabled" do
    stub_features(google_tools: true) do
      Current.set(user: users(:keith)) do
        assert users(:keith).gmail_credential
        assert Toolbox.descendants.include? Toolbox::Gmail
      end
    end
  end

  test "tool excludes gmail if disabled" do
    stub_features(google_tools: false) do
      Current.set(user: users(:keith)) do
        assert users(:keith).gmail_credential
        refute Toolbox.descendants.include? Toolbox::Gmail
      end
    end

    stub_features(google_tools: true) do
      Current.set(user: users(:rob)) do
        refute users(:rob).gmail_credential
        refute Toolbox.descendants.include? Toolbox::Gmail
      end
    end
  end

  test "tools includes brave search if the user has a Brave API key configured" do
    Current.set(user: users(:keith)) do
      assert Toolbox.descendants.include? Toolbox::BraveSearch
    end
  end

  test "tools excludes brave search if the user has no Brave API key configured" do
    api_services(:keith_brave_service).update!(token: nil)

    stub_features(default_llm_keys: false) do
      stub_settings(default_brave_key: nil) do
        Current.set(user: users(:keith)) do
          refute Toolbox.descendants.include? Toolbox::BraveSearch
        end
      end
    end
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

  test "best_match_index picks the closest option, the earliest winning a tie" do
    toolbox = Toolbox.new
    assert_equal 1, toolbox.send(:best_match_index, "Groceries", ["Work", "Groceries", "Grocery"]), "The exact match should win"
    assert_equal 0, toolbox.send(:best_match_index, "x", ["Same", "Same"]), "A tie should go to the earliest option"
  end

  test "best_match_index is nil when nothing scores above the threshold" do
    toolbox = Toolbox.new
    assert_nil toolbox.send(:best_match_index, "Groceries", ["Work"], threshold: 0.7), "A weak match should not count"
    assert_nil toolbox.send(:best_match_index, "Groceries", []), "No options should mean no match"
  end
end
