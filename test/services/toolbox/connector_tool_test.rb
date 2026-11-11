require "test_helper"

class Toolbox::ConnectorToolTest < ActiveSupport::TestCase
  setup do
    @connector = connectors(:github)
    @tool = Toolbox::ConnectorTool.new(@connector, @connector.tools.first)
  end

  test "new takes the name, description and schema FROM THE SERVER'S tool" do
    assert_equal "connector#{@connector.id}_search_issues", @tool.name
    assert_equal "Search issues and pull requests across repositories", @tool.description
    assert_equal @connector.tools.first["inputSchema"], @tool.parameters_schema, "The model should see the server's own input schema"
  end

  test "new LEAVES OUT the schema's $schema dialect marker" do
    tool = Toolbox::ConnectorTool.new(@connector, { "name" => "ping", "inputSchema" => { "$schema" => "http://json-schema.org/draft-07/schema#", "type" => "object", "properties" => {} } })

    assert_equal({ "type" => "object", "properties" => {} }, tool.parameters_schema, "Some providers reject a schema carrying $schema")
  end

  test "new FALLS BACK to the tool's name and an empty schema when the server gives neither a description nor a schema" do
    tool = Toolbox::ConnectorTool.new(@connector, { "name" => "ping" })

    assert_equal "ping", tool.description, "Providers expect a description"
    assert_equal({ "type" => "object", "properties" => {} }, tool.parameters_schema)
  end

  test "call RETURNS the text the server sent, with a note for the user" do
    stub_mcp_server(@connector.url, call_result: { content: [{ type: "text", text: "#12 Crash on save" }, { type: "text", text: "#15 Typo" }], isError: false })

    result = JSON.parse(@tool.call(query: "bug"))

    assert_equal "GitHub: search_issues", result["message_to_user"], "The user should see which connector tool ran"
    assert_equal "#12 Crash on save\n\n#15 Typo", result["result"], "Every text block should reach the model"
    assert_requested :post, @connector.url, body: hash_including("params" => { "name" => "search_issues", "arguments" => { "query" => "bug" } })
  end

  test "call DESCRIBES content that isn't text and falls back to structured content" do
    stub_mcp_server(@connector.url, call_result: { content: [{ type: "image", data: "aGk=", mimeType: "image/png" }, { type: "resource_link", name: "README", uri: "file:///README.md" }] })
    assert_equal "[image content]\n\nREADME (file:///README.md)", JSON.parse(@tool.call(query: "bug"))["result"]

    stub_mcp_server(@connector.url, call_result: { content: [], structuredContent: { count: 2 } })
    assert_equal({ "count" => 2 }.to_json, JSON.parse(@tool.call(query: "bug"))["result"], "Structured content should stand in for missing text")
  end

  test "call reports a tool that FAILED ON THE SERVER as an error" do
    stub_mcp_server(@connector.url, call_result: { content: [{ type: "text", text: "Repository not found" }], isError: true })

    result = JSON.parse(@tool.call(query: "bug"))

    assert_equal "Repository not found", result["error"], "The model should be told the tool failed"
    refute result.key?("result")
  end

  test "call returns the friendly error text when the server CAN'T BE REACHED" do
    stub_request(:post, @connector.url).to_raise(Faraday::ConnectionFailed.new("Connection refused"))

    result = @tool.call(query: "bug")

    assert result.start_with?('"An unexpected error occurred (Could not reach the server'), "The model should be told the tool failed, not crash the job"
  end
end
