# frozen_string_literal: true

# Steps for message content rendering, mirroring
# test/system/conversations/messages/html_test.rb and later message-content
# ports.

Then("the first message's content renders its source text unescaped") do
  conversation = conversations(:greeting)
  orig_msg_text = conversation.messages.ordered.first.content_text
  displayed_msg_text = first_message.find_role("content-text").text
  assert_equal orig_msg_text, displayed_msg_text, "The HTML tag was not escaped"
end

Then("the third message's content preserves its newlines") do
  conversation = conversations(:greeting)
  orig_msg_text = conversation.messages.ordered.third.content_text
  displayed_msg_text = find_messages.third.find_role("content-text").text
  assert_equal orig_msg_text.gsub("\n\n", "\n").strip, displayed_msg_text, "Newlines within a paragraph are not preserved"
end
