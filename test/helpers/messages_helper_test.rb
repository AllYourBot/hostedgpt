require "test_helper"

class MessagesHelperTest < ActionView::TestCase

  test "message_to_user_from_tool_call responds properly for tool result" do
    message = messages(:keep_memory_tool_result)
    assert message_to_user_from_tool_call?(message)
  end

  test "from_name_for responds properly for tool result" do
    message = messages(:keep_memory_tool_result)
    assert_nil from_name_for(message)
  end

  test "a tool result carrying link_url renders as a link to the URL the tool built" do
    message = tool_result_message(
      function_name: "bravesearch_brave_search",
      result: { message_to_user: "Web query: Sandi Metz", link_url: "https://search.brave.com/search?q=Sandi%20Metz" }
    )

    html = format_for_display(message)

    assert_link_to html, "https://search.brave.com/search?q=Sandi%20Metz", text: "Web query: Sandi Metz"
  end

  test "a tool result with a non-https link_url never renders that URL as an anchor" do
    message = tool_result_message(
      function_name: "bravesearch_brave_search",
      result: { message_to_user: "Web query: Sandi Metz", link_url: "javascript:alert(1)" }
    )

    html = format_for_display(message)

    # The scheme guard rejects the URL and the legacy branch renders its own
    # safe brave link built from the query text instead.
    refute_includes html, "javascript:"
    assert_link_to html, "https://search.brave.com/search?q=+Sandi+Metz", text: "Web query: Sandi Metz"
  end

  test "legacy googlesearch results render as a google link even without link_url" do
    message = tool_result_message(
      function_name: "googlesearch_google_search",
      result: { message_to_user: "Web query: Sandi Metz" }
    )

    html = format_for_display(message)

    assert_link_to html, "https://www.google.com/search?q=+Sandi+Metz", text: "Web query: Sandi Metz"
  end

  test "legacy bravesearch results without link_url still render as a brave link" do
    message = tool_result_message(
      function_name: "bravesearch_brave_search",
      result: { message_to_user: "Web query: Sandi Metz" }
    )

    html = format_for_display(message)

    assert_link_to html, "https://search.brave.com/search?q=+Sandi+Metz", text: "Web query: Sandi Metz"
  end

  test "memory tool results link to the memories settings page" do
    message = messages(:keep_memory_tool_result)

    html = format_for_display(message)

    assert_link_to html, settings_memories_path
  end

  test "other tool results render as plain text" do
    message = tool_result_message(
      function_name: "helloworld_hi",
      result: { message_to_user: "Hello!" }
    )

    html = format_for_display(message)

    assert_includes html, "Hello!"
    refute_includes html, "<a "
  end

  private

  def tool_result_message(function_name:, result:)
    Message.new(
      role: :tool,
      content_text: result.to_json,
      content_tool_calls: { index: 0, id: "call_test", type: "function", function: { name: function_name, arguments: "{}" } }
    )
  end

  def assert_link_to(html, href, text: nil)
    anchor = Nokogiri::HTML.fragment(html).at_css("a[href='#{href}']")
    assert anchor, "expected an anchor with href #{href} in: #{html}"
    assert_equal text, anchor.text.strip if text
  end
end
