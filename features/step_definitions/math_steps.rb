# frozen_string_literal: true

# Steps for math typesetting, mirroring
# test/system/conversations/messages/math_test.rb.

MATH_CONTENT = 'Euler: $$e^{i\\pi}+1=0$$ and inline \\(x^2\\) here'.freeze

Given("the greeting conversation's \"im_a_bot\" message holds math content") do
  messages(:im_a_bot).update!(content_text: MATH_CONTENT)
end

Then("the math message typesets with no raw delimiters") do
  msg = find("#message_#{messages(:im_a_bot).id}")
  assert msg.has_selector?(".katex"), "math should typeset on load"
  assert msg.has_no_text?("$$"), "no raw delimiters should remain"
end

When("the stub reply is updated to the math content and broadcast") do
  @stream_msg = conversations(:greeting).messages.ordered.last
  @stream_msg.update!(content_text: MATH_CONTENT)
  GetNextAIMessageJob.broadcast_updated_message(@stream_msg)
end

When("the stub reply is updated to the math content and broadcast while thinking") do
  @stream_msg = conversations(:greeting).messages.ordered.last
  @stream_msg.update!(content_text: MATH_CONTENT)
  GetNextAIMessageJob.broadcast_updated_message(@stream_msg, thinking: true)
end

Then("the settled math typesets") do
  assert page.has_selector?("#message_#{@stream_msg.id} .katex"),
    "the settled math typesets"
end

Then("the settle broadcast flips the render gate back off") do
  assert page.has_selector?("#message_#{@stream_msg.id} [data-role='content-text'][data-streaming='false']"),
    "the settle broadcast flips the render gate back off"
end

Then("KaTeX must not re-typeset while the reply streams") do
  # Out of the observer debounce: an ungated typeset would have run by now.
  sleep 0.6
  assert_equal 0, page.evaluate_script(
    "document.querySelectorAll('#message_#{@stream_msg.id} .katex').length"
  ), "KaTeX must not re-typeset while the reply streams"
end

Then("the math source stays readable mid-stream") do
  assert find("#message_#{@stream_msg.id}").has_text?("$$e^{i\\pi}+1=0$$"), "the math source stays readable mid-stream"
end
