# frozen_string_literal: true

# Steps for conversation version navigation, mirroring
# test/system/conversations/messages/version_test.rb.

Given("the versioned conversation's v2 branch is trimmed past index 2") do
  conversations(:versioned).messages.where(version: 2).where("index > 2").destroy_all
end

Given("message3_v1 is removed from the versioned conversation") do
  messages(:message3_v1).destroy
end

Given("I am on the versioned conversation at version {int}") do |version|
  visit_and_scroll_wait conversation_messages_path(conversations(:versioned), version: version)
end

Then("the previous version icon shows its tooltip") do
  assert_shows_tooltip hover_last_message.find_role("previous"), "Previous"
end

Then("the next version icon shows its tooltip") do
  assert_shows_tooltip hover_last_message.find_role("next"), "Next"
end

Then("the next version icon is disabled") do
  assert last_message.find_role("next").disabled?
end

Then("the previous version icon is disabled") do
  assert last_message.find_role("previous").disabled?
end

Then("the v1 branch's last message is the selected assistant's last message") do
  last_msg_v1 = messages(:message2_v1)

  assert_selected_assistant last_msg_v1.assistant
  assert_last_message last_msg_v1
end

Then("the v2 branch's last message is the selected assistant's last message") do
  last_msg_v2 = messages(:message5_v2)

  assert_selected_assistant last_msg_v2.assistant
  assert_last_message last_msg_v2
end

When("the window is shortened and the nav column is scrolled down slightly") do
  resize_browser_to(1400, 500)
  page.execute_script("document.querySelector('#nav-scrollable').scrollTop = 20") # scroll the nav column down slightly

  assert_at_bottom
end

When("I switch to the next version without scrolling the nav") do
  assert_did_not_scroll "#nav-scrollable" do
    msg = hover_last_message
    next_version = msg.find_role("next")
    next_version.click
  end
end

Then("the page is at the bottom") do
  assert_at_bottom
end
