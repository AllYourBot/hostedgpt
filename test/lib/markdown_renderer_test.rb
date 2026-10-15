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
end
