require "test_helper"

class Toolbox::BraveSearchTest < ActiveSupport::TestCase
  setup do
    @tool = Toolbox::BraveSearch.new
  end

  test "brave_search returns formatted results" do
    response = {
      web: {
        results: [
          { title: "POODR", url: "https://www.poodr.com", description: "Practical Object-Oriented Design in Ruby by Sandi Metz." },
          { title: "Sandi Metz", url: "https://www.sandimetz.com", description: "Sandi Metz's home page." },
        ]
      }
    }

    Current.set(user: users(:keith)) do
      stub_get_response(:brave_search, status: 200, response:) do
        result = @tool.brave_search(query_s: "Sandi Metz POODR")

        assert_equal "Web query: Sandi Metz POODR", result[:message_to_user]
        assert_equal (
          "POODR (https://www.poodr.com): Practical Object-Oriented Design in Ruby by Sandi Metz.\n" \
          "Sandi Metz (https://www.sandimetz.com): Sandi Metz's home page."
        ), result[:query_results]
      end
    end
  end

  test "brave_search returns a friendly message when there are no results" do
    Current.set(user: users(:keith)) do
      stub_get_response(:brave_search, status: 200, response: { query: { original: "asdfasdfasdf" } }) do
        result = @tool.brave_search(query_s: "asdfasdfasdf")
        assert_equal "No results found.", result[:query_results]
      end
    end
  end

  test "brave_search raises a clear error when the user has no Brave API key" do
    api_services(:keith_brave_service).update!(token: nil)

    Current.set(user: users(:keith)) do
      stub_features(default_llm_keys: false) do
        stub_settings(default_brave_key: nil) do
          error = assert_raises(RuntimeError) { @tool.brave_search(query_s: "anything") }
          assert_includes error.message, "Brave API key not found"
        end
      end
    end
  end

  test "brave_search works as a tool call" do
    response = {
      web: {
        results: [
          { title: "POODR", url: "https://www.poodr.com", description: "Practical Object-Oriented Design in Ruby by Sandi Metz." },
        ]
      }
    }

    Current.set(user: users(:keith)) do
      stub_get_response(:brave_search, status: 200, response:) do
        result = Toolbox.call("bravesearch_brave_search", query: "Sandi Metz POODR")
        assert_equal "Web query: Sandi Metz POODR", result[:message_to_user]
      end
    end
  end
end
