require "test_helper"

class Settings::ConnectorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @connector = connectors(:github)
    login_as users(:keith)
  end

  test "should get index" do
    get settings_connectors_url
    assert_response :success
    assert_contains_text "div#nav-container", "Connectors"
    assert_select "table#connectors tbody tr", count: users(:keith).connectors.count
    assert_contains_text "#connector_#{@connector.id}", "GitHub"
    assert_contains_text "#connector_#{@connector.id}", "1 of 2"
    assert_select "p a", "Add New"
    assert_select "p#no-connectors", false
  end

  test "should get index WITHOUT a table when the user HAS NO connectors" do
    get logout_url
    login_as users(:rob)
    get settings_connectors_url
    assert_response :success
    assert_select "table", count: 0
    assert_select "p#no-connectors", "You have no connectors."
  end

  test "should get new" do
    get new_settings_connector_url
    assert_response :success
    assert_select "input[name=?]", "connector[url]"
    assert_select "input[name=?][placeholder=?]", "connector[token]", "Optional. Sent as a Bearer token if the server needs one."
    assert_select "#connector-tools", false, "A new connector has no tools to list yet"
  end

  test "on create should list the server's tools & save the connector" do
    url = "https://mcp.example.com/calendar"
    stub_mcp_server(url, tools: [{ name: "list_events", description: "List events" }])

    assert_difference "Connector.count", 1 do
      post settings_connectors_url, params: { connector: { name: "Calendar", url:, token: "cal-secret" } }
    end

    assert_redirected_to settings_connectors_url
    assert_equal "Saved", flash[:notice]
    connector = Connector.last
    assert_equal users(:keith), connector.user, "The connector should belong to the current user"
    assert_equal "cal-secret", connector.token
    assert_equal ["list_events"], connector.tool_names, "The server's tools should be saved"
  end

  test "should not create connector when the server CAN'T BE REACHED" do
    url = "https://mcp.example.com/calendar"
    stub_request(:post, url).to_raise(Faraday::ConnectionFailed.new("Connection refused"))

    assert_no_difference "Connector.count" do
      post settings_connectors_url, params: { connector: { name: "Calendar", url: } }
    end

    assert_response :unprocessable_content
    assert_contains_text "#error_explanation", "Couldn't load the tools: Could not reach the server: Connection refused"
  end

  test "should get edit WITH the tools checked as they're enabled" do
    get edit_settings_connector_url(@connector)
    assert_response :success
    assert_select "h1", "Editing GitHub"
    assert_select "input[name=?][placeholder=?]", "connector[token]", "A token is set. Leave blank to keep it."
    assert_select "input[name=?][value]", "connector[token]", false, "The saved token should never be shown"
    assert_select "#connector-tools input[type=checkbox][value=search_issues][checked]", 1
    assert_select "#connector-tools input[type=checkbox][value=create_issue]:not([checked])", 1
    assert_contains_text "main", "Delete"
  end

  test "on update should save the checked tools, refresh the tools & keep a token left blank" do
    stub_mcp_server(@connector.url, tools: @connector.tools)

    patch settings_connector_url(@connector), params: { connector: { name: "GitHub Work", url: @connector.url, token: "", enabled_tool_names: ["", "create_issue"] } }

    assert_redirected_to settings_connectors_url
    @connector.reload
    assert_equal "GitHub Work", @connector.name
    assert_equal ["create_issue"], @connector.enabled_tool_names, "Only the checked tool should stay enabled"
    assert_equal "ghp-secret", @connector.token, "A blank token field should keep the saved token"
    assert_requested :post, @connector.url, body: hash_including("method" => "tools/list")
  end

  test "on update should REPLACE the token when a new one is entered" do
    stub_mcp_server(@connector.url, tools: @connector.tools)

    patch settings_connector_url(@connector), params: { connector: { token: "ghp-new" } }

    assert_redirected_to settings_connectors_url
    assert_equal "ghp-new", @connector.reload.token
    assert_requested :post, @connector.url, headers: { "Authorization" => "Bearer ghp-new" }, at_least_times: 1
  end

  test "should not update connector when the server CAN'T BE REACHED" do
    stub_request(:post, @connector.url).to_return(status: 500)

    patch settings_connector_url(@connector), params: { connector: { name: "GitHub Work" } }

    assert_response :unprocessable_content
    assert_contains_text "#error_explanation", "The server answered with HTTP 500"
    assert_equal "GitHub", @connector.reload.name, "Nothing should be saved"
  end

  test "should not edit, update or destroy ANOTHER USER'S connector" do
    connector = users(:rob).connectors.create!(name: "Rob's", url: "https://mcp.example.com/rob")

    get edit_settings_connector_url(connector)
    assert_redirected_to settings_connectors_url
    assert_equal "The connector could not be found", flash[:alert]

    patch settings_connector_url(connector), params: { connector: { name: "Mine now" } }
    assert_redirected_to settings_connectors_url
    assert_equal "Rob's", connector.reload.name

    assert_no_difference "Connector.count" do
      delete settings_connector_url(connector)
    end
    assert_redirected_to settings_connectors_url
  end

  test "should destroy connector" do
    assert_difference "Connector.count", -1 do
      delete settings_connector_url(@connector)
    end

    assert_redirected_to settings_connectors_url
    assert_equal "Deleted", flash[:notice]
  end
end
