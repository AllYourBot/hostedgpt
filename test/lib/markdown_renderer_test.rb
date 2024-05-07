require 'test_helper'

class MarkdownRendererTest < ActiveSupport::TestCase
  test 'ensure_newline_before_code_block_start adds newline before code block' do
    markdown = "Text before code block\n```ruby\ncode block\n```"
    expected = "Text before code block\n\n```ruby\ncode block\n```"
    assert_equal expected, MarkdownRenderer.ensure_newline_before_code_block_start(markdown)
  end

  test 'ensure_newline_before_code_block_start does not add newline when one is already present' do
    markdown = "Text before code block\n\n```ruby\ncode block\n```"
    expected = "Text before code block\n\n```ruby\ncode block\n```"
    assert_equal expected, MarkdownRenderer.ensure_newline_before_code_block_start(markdown)
  end

  test 'ensure_newline_before_code_block_start does not add newline inside code block' do
    markdown = "```ruby\ncode\nblock\n```"
    expected = "```ruby\ncode\nblock\n```"
    assert_equal expected, MarkdownRenderer.ensure_newline_before_code_block_start(markdown)
  end

  test 'ensure_newline_before_code_block_start handles multiple code blocks' do
    markdown = "Text\n```ruby\ncode block\n```\nMore text\n```ruby\nanother code block\n```"
    expected = "Text\n\n```ruby\ncode block\n```\nMore text\n\n```ruby\nanother code block\n```"
    assert_equal expected, MarkdownRenderer.ensure_newline_before_code_block_start(markdown)
  end
end
