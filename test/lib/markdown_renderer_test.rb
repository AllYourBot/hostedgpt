require "test_helper"

class MarkdownRendererTest < ActiveSupport::TestCase
  # See lib/redcarpet/* tests

  test "$$ display math passes through untouched" do
    html = MarkdownRenderer.render_for_display("math $$x^2$$ here")
    assert_includes html, "$$x^2$$"
  end

  test "\\( \\) inline math survives Redcarpet" do
    html = MarkdownRenderer.render_for_display('math \\(a^2\\) here')
    assert_includes html, '\\(a^2\\)'
  end

  test "\\[ \\] display math survives Redcarpet" do
    html = MarkdownRenderer.render_for_display('math \\[x^2\\] here')
    assert_includes html, '\\[x^2\\]'
  end

  test "$5 currency stays literal, not math" do
    html = MarkdownRenderer.render_for_display("Price is $5 here")
    assert_includes html, "$5"
    refute_includes html, "MATHSPAN"
  end

  test "fenced code language is preserved for block_code" do
    captured = nil
    html = MarkdownRenderer.render_for_display(
      "```ruby\nputs 1\n```",
      block_code: ->(code, lang) { captured = lang; "<pre>#{code}</pre>" }
    )
    assert_equal "ruby", captured
    assert_includes html, "<pre>"
  end
end
