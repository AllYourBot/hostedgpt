# frozen_string_literal: true

# Steps for the conversations sidebar, mirroring test/system/conversations_test.rb.

When("I hover the greeting conversation") do
  hover_conversation conversations(:greeting)
end

When("I hover the javascript conversation") do
  hover_conversation conversations(:javascript)
end

Then("the options icon shows its tooltip") do
  assert_shows_tooltip @convo_node.find_role("options"), "Options"
end

When("I open the conversation options") do
  @convo_node.find_role("options").click

  assert_true { @convo_node.find_role("edit").visible? }
end

When("I click the edit option") do
  @convo_node.find_role("edit").click
end

When("I click the delete option") do
  @convo_node.find_role("delete").click
end

When("I rename the conversation to {string} by clicking elsewhere") do |title|
  fill_in "edit-conversation", with: title
  find("body").click
  wait_for_conversation_title(title)
end

When("I rename the conversation to {string} with enter") do |title|
  fill_in "edit-conversation", with: title
  send_keys "enter"
  wait_for_conversation_title(title)
end

When("I rename the conversation to {string} and press esc") do |title|
  fill_in "edit-conversation", with: title
  send_keys "esc"
end

Then("the conversation shows {string}") do |title|
  assert_true "UI never reverted back to the old title '#{conversations(:greeting).reload.title}'" do
    @convo_node.text == title
  end
end

Then("the conversation is titled {string} in the database") do |title|
  assert_equal title, conversations(:greeting).reload.title
end

Then("the path has not changed since I signed in") do
  assert_current_path @signed_in_path
end

Then("the alert is still visible") do
  assert_visible "#alerts .alert", "The alert should stay up while the sidebar conversations load"
end

When("I open the javascript conversation") do
  find("#conversation-#{conversations(:javascript).id} a[data-role='title']").click

  assert_current_path conversation_messages_path(conversations(:javascript)), ignore_query: true
end

Then("the alert is hidden") do
  assert_hidden "#alerts .alert", "The alert should be dismissed once another conversation opens"
end

When("the screen is narrow") do
  resize_browser_to(400, 800)
end

When("I toggle the nav open") do
  find("[data-role='nav-toggle']").click

  assert_visible "#nav-column"
end

When("I open the greeting conversation from the nav") do
  find("#conversation-#{conversations(:greeting).id} a[data-role='title']").click

  assert_hidden "#nav-column"
end

Then("I am on the greeting conversation's messages") do
  assert_current_path conversation_messages_path(conversations(:greeting)), ignore_query: true
end

Then("the first message is the hear-me fixture message") do
  assert_first_message messages(:hear_me)
end

def hover_conversation(conversation)
  assert_visible "#conversation-#{conversation.id} a[data-role='title']"
  @convo_node = find("#conversation-#{conversation.id}")
  @convo_node.hover
  @convo_node
end

def wait_for_conversation_title(title)
  # The save is async (the system test sleeps 1s here); wait for both the UI
  # and the database to agree.
  assert_true "waiting for the conversation title to save as '#{title}'" do
    @convo_node.text == title && conversations(:greeting).reload.title == title
  end
end
