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

  test "block_code perfectly formatted" do
    markdown = <<~MD
      This is sql:

      ```sql
      SELECT * FROM users;
      ```

      Line after.
    MD

    formatted = <<~HTML
      <p>This is sql:</p>

      <pre><code class="sql">SELECT * FROM users;
      </code></pre>

      <p>Line after.</p>
    HTML

    assert_equal formatted.strip, @renderer.render(markdown).strip
  end

  test "block_code missing a blank line before and after - ensure_newline_before_code_block_start" do
    markdown = <<~MD
      This is sql:
      ```sql
      SELECT * FROM users;
      ```
      Line after.
    MD

    formatted = <<~HTML
      <p>This is sql:</p>

      <pre><code class="sql">SELECT * FROM users;
      </code></pre>

      <p>Line after.</p>
    HTML

    assert_equal formatted.strip, @renderer.render(markdown).strip
  end

  test "block_code can be provided with a proc" do
    markdown = <<~MD
      This is sql:

      ```sql
      SELECT * FROM users;
      ```

      Line after.
    MD

    formatted = <<~HTML
      <p>This is sql:</p>
      <CODE lang="sql">SELECT * FROM users;
      </CODE>
      <p>Line after.</p>
    HTML

    block_code = -> (code, language) do
      %(<CODE lang="#{language}">#{code}</CODE>)
    end

    assert_equal formatted.strip, @renderer.render(markdown, block_code: block_code).strip
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

  test "code_sanitization removes_script_tags" do
    markdown = "Here is dangerous input: `<script>alert('bad');</script>`"
    # Expect script to be sanitized, but code to be properly marked up as such
    formatted = "<p>Here is dangerous input: <code>&lt;script&gt;alert(&#39;bad&#39;);&lt;/script&gt;</code></p>\n"

    assert_equal formatted.strip, @renderer.render(markdown).strip
  end

  test "html_inside_code_tags_is_correctly_sanitized" do
    # Input markdown with HTML that should be sanitized
    markdown = "Display HTML code `<div>Some content</div>` safely."

    # Expected output ensures that HTML tags are escaped, and contents remain inside code tags
    expected_output = "<p>Display HTML code <code>&lt;div&gt;Some content&lt;/div&gt;</code> safely.</p>\n"

    # Render the markdown and ensure the output is as expected
    assert_equal expected_output.strip, @renderer.render(markdown).strip
  end
end
