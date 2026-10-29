require "test_helper"

class CustomSpeakingRendererTest < ActiveSupport::TestCase
  setup do
    @renderer = MarkdownRenderer
  end

  test "code_span" do
    markdown  = "This is `code` inline. This is a bullet:\n\n* Bullet"
    formatted = "This is `code` inline. This is a bullet:\n\n* Bullet"
    assert_equal formatted, @renderer.render_for_speaking(markdown)
  end

  test "block_code with a language that gets the word 'code'" do
    markdown  = "This is an example:\n```ruby\ncode\n```\n"
    formatted = "This is an example:\nHere is some ruby code.\n"
    assert_equal formatted, @renderer.render_for_speaking(markdown)
  end

  test "block_code with a language that stands on its own'" do
    markdown  = "This is an example:\n```html\ncode\n```\n"
    formatted = "This is an example:\nHere is some html.\n"
    assert_equal formatted, @renderer.render_for_speaking(markdown)
  end

  test "block_code with no language rewrites properly" do
    markdown  = "This is an example:\n```\ncode\n```\n"
    formatted = "This is an example:\nHere is some code.\n"
    assert_equal formatted, @renderer.render_for_speaking(markdown)
  end

  test "block_code that is incomplete is hidden, because we are parsing a partially streamed response" do
    markdown  = "This is an example:\n```\nthis is a partially completed response"
    formatted = "This is an example:\n"
    assert_equal formatted, @renderer.render_for_speaking(markdown)
  end

  test "markdown links are caught" do
    markdown  = "Try visiting [Google](https://google.com)"
    formatted = "Try visiting Here is a link to Google"
    assert_equal formatted, @renderer.render_for_speaking(markdown)
  end

  test "regular URLs are caught" do
    markdown  = "Try visiting https://google.com"
    formatted = "Try visiting this link"
    assert_equal formatted, @renderer.render_for_speaking(markdown)
  end
end
