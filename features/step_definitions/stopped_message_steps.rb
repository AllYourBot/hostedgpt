# frozen_string_literal: true

# Steps for stopped-message icons, mirroring
# test/system/conversations/messages/stop_streaming_test.rb.

Given("the {string} message is an empty cancelled reply") do |fixture|
  messages(fixture.to_sym).update!(content_text: nil, cancelled_at: Time.current)
end

Given("the {string} message is a cancelled reply reading {string}") do |fixture, text|
  messages(fixture.to_sym).update!(content_text: text, cancelled_at: Time.current)
end

Then("the message's content renders as empty") do
  msg = find("#message_#{messages(:dont_know_day).id}")

  assert_equal "", msg.find_role("content-text").text
end

Then("the message's content ends with \"...\"") do
  msg = find("#message_#{messages(:dont_know_day).id}")

  assert msg.find_role("content-text").text.include?("...")
end

Then("the stopped icon is visible") do
  assert find("#message_#{messages(:dont_know_day).id}").find_role("cancelled").visible?
end
