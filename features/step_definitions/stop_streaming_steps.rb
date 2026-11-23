# frozen_string_literal: true

# Steps for the composer's stop button, mirroring
# test/system/messages/composer/stop_streaming_test.rb.

Then("the composer shows the stop button") do
  assert_selector "#composer #cancel"
end

Then("the composer hides the stop button") do
  assert_no_selector "#composer #cancel"
end

When("the assistant reply streams {string} and finishes") do |text|
  stream_ai_message conversations(:greeting).messages.ordered.last, text
  finish_streaming
end

When("the assistant reply streams {string}") do |text|
  stream_ai_message conversations(:greeting).messages.ordered.last, text
end

Then("the reply is not cancelled") do
  refute conversations(:greeting).messages.ordered.last.reload.cancelled?
end

When("I click the composer's stop button") do
  click_element "#composer #cancel"
end

When("I press the stop keyboard shortcut") do
  send_keys "meta+esc"
end

Then("the reply becomes cancelled") do
  reply = conversations(:greeting).messages.ordered.last
  assert_true { reply.reload.cancelled? }
end

def stream_ai_message(msg, text)
  msg.update!(content_text: text)
  GetNextAIMessageJob.broadcast_updated_message(msg)
  sleep 1 # without this I get a stale element reference on this next line which I cannot understand...
  assert_true(wait: 10) do
    last_message.text.include?(msg.content_text)
  end
end

def finish_streaming = conversations(:greeting).broadcast_refresh
