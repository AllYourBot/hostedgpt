require "test_helper"

class MessagesHelperTest < ActionView::TestCase

  test "message_sources DEDUPES by url, DROPS unsafe or missing urls and falls back to the host for a title" do
    message = Message.new(content_citations: [
      { "url" => "https://a.test/page", "title" => "A", "cited_text" => "one" },
      { "url" => "https://a.test/page", "title" => "A again", "cited_text" => "two" },
      { "url" => "https://b.test/", "title" => nil },
      { "url" => "javascript:alert(1)", "title" => "Bad" },
      { "url" => "http://plain.test/", "title" => "Plain" },
      { "url" => nil, "title" => "Nowhere" },
    ])

    assert_equal(
      [{ url: "https://a.test/page", title: "A" }, { url: "https://b.test/", title: "b.test" }],
      message_sources(message),
      "Only https sources should show, once each, titled by host when untitled"
    )
  end

  test "message_sources is EMPTY for a message without citations" do
    assert_empty message_sources(Message.new), "No citations means no sources"
  end

  test "message_to_user_from_tool_call responds properly for tool result" do
    message = messages(:keep_memory_tool_result)
    assert message_to_user_from_tool_call?(message)
  end

  test "from_name_for responds properly for tool result" do
    message = messages(:keep_memory_tool_result)
    assert_nil from_name_for(message)
  end

  test "an AskUser result renders the question as regular text, not a grey tool note" do
    message = tool_result_message(function_name: "askuser_ask_user", result: { message_to_user: "Which plan?", choices: ["Free", "Pro"] })

    html = format_for_display(message)

    assert_includes html, "Which plan?", "The question should be shown"
    refute_includes html, "text-gray-400", "The question is part of the conversation, not a tool note"
  end

  test "an AskUser result ESCAPES html in the question" do
    message = tool_result_message(function_name: "askuser_ask_user", result: { message_to_user: "<b>x</b>", choices: [] })

    html = format_for_display(message)

    assert_includes html, "&lt;b&gt;x&lt;/b&gt;", "The model's question should be escaped"
    refute_includes html, "<b>", "No markup from the model should reach the page"
  end

  test "ask_user_choices returns the choices of an AskUser result and NOTHING for other tools" do
    ask = tool_result_message(function_name: "askuser_ask_user", result: { message_to_user: "Which?", choices: ["A", "B"] })
    other = tool_result_message(function_name: "helloworld_hi", result: { message_to_user: "Hi", choices: ["A"] })

    assert_equal ["A", "B"], ask_user_choices(ask), "An AskUser result offers its choices"
    assert_empty ask_user_choices(other), "Another tool's result offers no choices"
    assert_empty ask_user_choices(Message.new(role: :assistant, content_text: "Hello")), "A plain reply offers no choices"
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

  test "assistant HTML is escaped but math delimiters survive" do
    message = Message.new(role: :assistant, content_text: '<script>alert(1)</script> math \\(x^2\\) here')

    html = view.format_for_display(message)

    refute_includes html, "<script>", "assistant markup must not render raw"
    assert_includes html, "&lt;script&gt;", "assistant markup should render escaped"
    assert_includes html, '\\(x^2\\)', "math delimiters should survive the escape"
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
