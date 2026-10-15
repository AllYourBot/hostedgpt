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
end
