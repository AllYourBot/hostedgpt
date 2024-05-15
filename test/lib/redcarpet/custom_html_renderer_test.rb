require "test_helper"

class CustomHtmlRendererTest < ActiveSupport::TestCase
  setup do
    @renderer = MarkdownRenderer
  end

  test "code_span" do
    markdown = "This is `code` inline."
    formatted = "<p>This is <code>code</code> inline.</p>\n"

    assert_equal formatted.strip, @renderer.render(markdown).strip
  end

  test "newlines within paragraphs get converted into BRs" do
    markdown = <<~MD
      This is the first paragraph

      This is a second paragraph
      with a line break.

      This is a third paragraph

    MD

    formatted = <<~HTML
      <p>This is the first paragraph</p>

      <p>This is a second paragraph<br>
      with a line break.</p>

      <p>This is a third paragraph</p>
    HTML

    assert_equal formatted.strip, @renderer.render(markdown).strip
  end
end
