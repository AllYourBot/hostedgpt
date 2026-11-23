# frozen_string_literal: true

include ActionView::RecordIdentifier

# Steps for message playback, mirroring
# test/system/conversations/messages/playback_test.rb.

Given("I am on the hello-claude conversation") do
  visit_and_scroll_wait conversation_messages_path(conversations(:hello_claude))
end

Then("the second assistant message's playback index is forced to 123") do
  page.execute_script("arguments[0].setAttribute('data-playback-sentences-index-value', '123')", second_assistant_message.native)
end

When("a new assistant message morphs the page") do
  assert_page_morphed do
    conversations(:hello_claude).messages.create!(role: :assistant, assistant: conversations(:hello_claude).assistant, content_text: "Hello, world!")
    conversations(:hello_claude).broadcast_refresh
  end
end

Then("the second assistant message keeps its 123 playback index") do
  assert_equal "123", second_assistant_message["data-playback-sentences-index-value"], "The playback sentence value should not have changed"
end

When("the second assistant message and its inner message are tagged for morph monitoring") do
  tag second_assistant_message
  tag second_assistant_message.find_role("inner-message")
end

When("the versioned reply streams {string}") do |text|
  msg = conversations(:hello_claude).latest_message_for_version(1)
  msg.content_text += text
  @versioned_msg = msg

  assert_equal second_assistant_message[:id], dom_id(msg)
  GetNextAIMessageJob.broadcast_updated_message(msg)
end

Then("the second assistant message streamed its update") do
  assert_true "The last message should have streamed an update" do
    second_assistant_message.text.include?("The quick brown")
  end
end

Then("the second assistant message stayed tagged") do
  assert tagged?(second_assistant_message)
end

Then("the inner message was replaced") do
  refute tagged?(second_assistant_message.find_role("inner-message"))
end

Then("the second assistant message's play button is visible and stop is not") do
  second_assistant_message.hover
  assert second_assistant_message.find_role("play").visible?
  refute second_assistant_message.find_role("stop").visible?
end

When("I click play on the second assistant message") do
  second_assistant_message.hover
  second_assistant_message.find_role("play").click
  refute second_assistant_message.find_role("play").visible?
end

Then("play becomes stop on the second assistant message") do
  assert second_assistant_message.find_role("stop").visible?, "Play should have changed to stop upon click"
end

When("I click stop on the second assistant message") do
  second_assistant_message.find_role("stop").click
end

Then("stop flips back to play on the second assistant message") do
  assert second_assistant_message.find_role("play").visible?, "Clicking stop should have flipped it back to play"
  refute second_assistant_message.find_role("stop").visible?
end

def first_assistant_message = find_messages.second

def second_assistant_message = find_messages.fourth
