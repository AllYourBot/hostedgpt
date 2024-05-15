require 'test_helper'

class MarkdownRendererTest < ActiveSupport::TestCase
  setup do
    @renderer = MarkdownRenderer
  end

  test 'ensure_blank_line_before_code_block_start adds blank line before code block when zero newlines' do
    markdown = "Text before code block```ruby\ncode block\n```"
    expected = "Text before code block\n\n```ruby\ncode block\n```"
    assert_equal expected, MarkdownRenderer.ensure_blank_line_before_code_block_start(markdown)

    markdown = "```ruby\ncode block\n```"
    expected = "\n\n```ruby\ncode block\n```"
    assert_equal expected, MarkdownRenderer.ensure_blank_line_before_code_block_start(markdown)

    markdown = "Text before code block```ruby\ncode block\n```Text before second```\ncode block\n```"
    expected = "Text before code block\n\n```ruby\ncode block\n```Text before second\n\n```\ncode block\n```"
    assert_equal expected, MarkdownRenderer.ensure_blank_line_before_code_block_start(markdown)
  end

  test 'ensure_blank_line_before_code_block_start adds blank line before code block when one newline' do
    markdown = "Text before code block\n```ruby\ncode block\n```"
    expected = "Text before code block\n\n```ruby\ncode block\n```"
    assert_equal expected, MarkdownRenderer.ensure_blank_line_before_code_block_start(markdown)

    markdown = "\n```ruby\ncode block\n```"
    expected = "\n\n```ruby\ncode block\n```"
    assert_equal expected, MarkdownRenderer.ensure_blank_line_before_code_block_start(markdown)

    markdown = "Text before code block\n```ruby\ncode block\n```Text before second\n```\ncode block\n```"
    expected = "Text before code block\n\n```ruby\ncode block\n```Text before second\n\n```\ncode block\n```"
    assert_equal expected, MarkdownRenderer.ensure_blank_line_before_code_block_start(markdown)
  end

  test 'ensure_blank_line_before_code_block_start does not add blank line when one is already present' do
    markdown = "Text before code block\n\n```ruby\ncode block\n```"
    expected = "Text before code block\n\n```ruby\ncode block\n```"
    assert_equal expected, MarkdownRenderer.ensure_blank_line_before_code_block_start(markdown)

    markdown = "\n\n```ruby\ncode block\n```"
    expected = "\n\n```ruby\ncode block\n```"
    assert_equal expected, MarkdownRenderer.ensure_blank_line_before_code_block_start(markdown)

    markdown = "Text before code block\n\n```ruby\ncode block\n```Text before second\n\n```\ncode block\n```"
    expected = "Text before code block\n\n```ruby\ncode block\n```Text before second\n\n```\ncode block\n```"
    assert_equal expected, MarkdownRenderer.ensure_blank_line_before_code_block_start(markdown)
  end

  test "block_code nicely formatted gets converted" do
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

  test "block_code missing a blank line before and after gets gets nicely - ensure_blank_line_before_code_block_start" do
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
end
