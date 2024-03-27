require "test_helper"

class CustomHtmlRendererTest < ActiveSupport::TestCase
  setup do
    @renderer = MarkdownRenderer
  end

  test "code_span" do
    markdown = "This is `code` inline."
    formatted = "<p>This is <code><span class=\"hidden\">`</span>code<span class=\"hidden\">`</span></code> inline.</p>\n"

    assert_equal formatted, @renderer.render(markdown)
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

    assert_equal formatted, @renderer.render(markdown)
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

    assert_equal formatted, @renderer.render(markdown)
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

    assert_equal formatted, @renderer.render(markdown,
      block_code: -> (code, language) do
        %(<CODE lang="#{language}">#{code}</CODE>)
      end
    )
  end
end
