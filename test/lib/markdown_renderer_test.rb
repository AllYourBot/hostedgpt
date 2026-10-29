require "test_helper"

class MarkdownRendererTest < ActiveSupport::TestCase
  test "$$ display math passes through untouched" do
    html = MarkdownRenderer.render_for_display("math $$x^2$$ here")
    assert_includes html, "$$x^2$$", "$$ math should reach the client verbatim"
  end

  test "\\( \\) inline math survives markdown rendering" do
    html = MarkdownRenderer.render_for_display('math \\(a^2\\) here')
    assert_includes html, '\\(a^2\\)', "inline math delimiters should survive markdown escapes"
  end

  test "\\[ \\] display math survives markdown rendering" do
    html = MarkdownRenderer.render_for_display('math \\[x^2\\] here')
    assert_includes html, '\\[x^2\\]', "display math delimiters should survive markdown escapes"
  end

  test "$5 currency stays literal, not math" do
    html = MarkdownRenderer.render_for_display("Price is $5 here")
    assert_includes html, "$5", "a single $ should stay literal"
    refute_includes html, "\uE000", "no math placeholder should be minted for currency"
  end

  test "fenced code language is preserved for block_code" do
    captured = nil
    html = MarkdownRenderer.render_for_display(
      "```ruby\nputs 1\n```",
      block_code: ->(code, lang) { captured = lang; "<pre>#{code}</pre>" }
    )
    assert_equal "ruby", captured, "the copy header needs the fence's language"
    assert_includes html, "<pre>", "the proc's markup should replace the code block"
  end

  test "math delimiters inside fenced code stay code, not math" do
    html = MarkdownRenderer.render_for_display(
      "```tex\n\\(a^2\\) and $$x$$ here\n```",
      block_code: ->(code, lang) { "<pre>#{code}</pre>" }
    )
    assert_includes html, "<pre>", "the fence should still render as code"
    assert_includes html, "\\(a^2\\) and $$x$$ here", "math inside the fence should stay as written"
    refute_includes html, "\uE000", "no math placeholder should leak into the output"
  end

  test "LaTeX backslash sequences round-trip through placeholders untouched" do
    html = MarkdownRenderer.render_for_display('\\(a \\\\ b \\& c\\)')
    assert_includes html, '\\(a \\\\ b \\& c\\)', "markdown backslash escapes should not touch math"
    refute_includes html, "\uE000", "every placeholder should be restored"
  end

  test "$$ display math survives markdown that would mangle it" do
    html = MarkdownRenderer.render_for_display("$$a*b*c$$ and $$x_1 + y_2$$")
    assert_includes html, "$$a*b*c$$", "asterisks inside math should not become emphasis"
    assert_includes html, "$$x_1 + y_2$$", "underscores inside math should not become emphasis"
    refute_includes html, "<em>", "math should never produce emphasis"
    refute_includes html, "<del>", "math should never produce strikethrough"
  end

  test "doubled-backslash delimiters from models normalize to the single form" do
    html = MarkdownRenderer.render_for_display('Before \\\\(x+1\\\\) after')
    assert_includes html, "\\(x+1\\)", "doubled delimiters should become the single form KaTeX pairs"
    refute_includes html, "\\\\(", "no doubled delimiter should remain"
  end

  test "unbalanced \\( that would devour a fence stays raw" do
    html = MarkdownRenderer.render_for_display("```\n\\(foo\n```\nbar\\)")
    assert_includes html, "<pre", "the fence should still close"
    assert_includes html, "<p>bar", "text after the fence should render outside it"
  end

  test "math spans carrying escaped markup cannot smuggle it into output" do
    html = MarkdownRenderer.render_for_display('\\(&lt;script&gt;alert(1)&lt;/script&gt;\\)')
    refute_includes html, "<script", "restored math spans should stay escaped"
  end

  test "indented four-space blocks render as code (CommonMark spec)" do
    html = MarkdownRenderer.render_for_display("para\n\n    four-space continuation\n\nafter")
    assert_includes html, "<pre", "an indented block should render as code"
  end

  test "task lists render as checkboxes" do
    html = MarkdownRenderer.render_for_display("- [ ] todo\n- [x] done\n")
    assert_includes html, 'type="checkbox"', "task items should render as checkboxes"
    assert_includes html, "checked", "a done task should render checked"
  end

  test "alerts render as callouts, not literal [!NOTE]" do
    html = MarkdownRenderer.render_for_display("> [!NOTE]\n> hello\n")
    refute_includes html, "[!NOTE]", "the alert marker should not render literally"
    assert_match(/note/i, html, "the alert should render as a note callout")
  end

  test "ascii-only input renders without encoding error" do
    html = MarkdownRenderer.render_for_display("plain ascii text")
    assert_includes html, "plain ascii text", "ascii input should render"
  end

  test "footnotes render as linked notes, not literal [^1]" do
    html = MarkdownRenderer.render_for_display("Claim[^1].\n\n[^1]: The source.\n")
    assert_includes html, "footnote", "the reference should render as a footnote"
    assert_includes html, "The source.", "the footnote text should render"
  end

  test "mermaid fence keeps its language so the client can preview it" do
    captured = nil
    html = MarkdownRenderer.render_for_display(
      "```mermaid\ngraph TD;\n```\n",
      block_code: ->(code, lang) { captured = lang; "<pre>#{code}</pre>" }
    )
    assert_equal "mermaid", captured, "diagram_controller finds fences by their mermaid language"
    assert_includes html, "graph TD;", "the diagram source should render"
  end

  test "pre-escaped entities in fenced code are not double-escaped" do
    html = MarkdownRenderer.render_for_display(
      "```\na--&gt;b\n```\n",
      block_code: ->(code, lang) { "<pre>#{code}</pre>" }
    )
    assert_includes html, "a--&gt;b", "fenced code should stay escaped exactly once"
    refute_includes html, "&amp;gt;", "fenced code should not be escaped twice"
  end

  test "pre-escaped entities in inline code spans are not double-escaped" do
    html = MarkdownRenderer.render_for_display("x `foo &lt;= 3` y")
    assert_includes html, "<code>foo &lt;= 3</code>", "inline code should stay escaped exactly once"
    refute_includes html, "&amp;", "inline code should not be escaped twice"
  end
end
