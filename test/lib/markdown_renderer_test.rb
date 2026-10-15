require "test_helper"

class MarkdownRendererTest < ActiveSupport::TestCase
  test "$$ display math passes through untouched" do
    html = MarkdownRenderer.render_for_display("math $$x^2$$ here")
    assert_includes html, "$$x^2$$"
  end

  test "\\( \\) inline math survives markdown rendering" do
    html = MarkdownRenderer.render_for_display('math \\(a^2\\) here')
    assert_includes html, '\\(a^2\\)'
  end

  test "\\[ \\] display math survives markdown rendering" do
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

  test "math delimiters inside fenced code stay code, not math" do
    html = MarkdownRenderer.render_for_display(
      "```tex\n\\(a^2\\) and $$x$$ here\n```",
      block_code: ->(code, lang) { "<pre>#{code}</pre>" }
    )
    assert_includes html, "<pre>"
    refute_includes html, "MATHSPAN"
  end

  test "LaTeX backslash sequences round-trip through placeholders untouched" do
    html = MarkdownRenderer.render_for_display('\\(a \\\\ b \\& c\\)')
    assert_includes html, '\\(a \\\\ b \\& c\\)'
    refute_includes html, [0xE000].pack("U")
  end

  test "$$ display math survives markdown that would mangle it" do
    html = MarkdownRenderer.render_for_display("$$a*b*c$$ and $$x_1 + y_2$$")
    assert_includes html, "$$a*b*c$$"
    assert_includes html, "$$x_1 + y_2$$"
    refute_includes html, "<em>"
    refute_includes html, "<del>"
  end

  test "doubled-backslash delimiters from models normalize to the single form" do
    html = MarkdownRenderer.render_for_display('Before \\\\(x+1\\\\) after')
    assert_includes html, "\\(x+1\\)"
    refute_includes html, "\\\\("
  end

  test "unbalanced \\( that would devour a fence stays raw" do
    html = MarkdownRenderer.render_for_display("```\n\\(foo\n```\nbar\\)")
    assert_includes html, "<pre"
    assert_includes html, "<p>bar"
  end

  test "math spans carrying escaped markup cannot smuggle it into output" do
    html = MarkdownRenderer.render_for_display('\\(&lt;script&gt;alert(1)&lt;/script&gt;\\)')
    refute_includes html, "<script"
  end

  test "indented four-space blocks render as code (CommonMark spec)" do
    html = MarkdownRenderer.render_for_display("para\n\n    four-space continuation\n\nafter")
    assert_includes html, "<pre"
  end

  test "task lists render as checkboxes" do
    html = MarkdownRenderer.render_for_display("- [ ] todo\n- [x] done\n")
    assert_includes html, 'type="checkbox"'
    assert_includes html, "checked"
  end

  test "alerts render as callouts, not literal [!NOTE]" do
    html = MarkdownRenderer.render_for_display("> [!NOTE]\n> hello\n")
    refute_includes html, "[!NOTE]"
    assert_match(/note/i, html)
  end

  test "ascii-only input renders without encoding error" do
    html = MarkdownRenderer.render_for_display("plain ascii text")
    assert_includes html, "plain ascii text"
  end
end
