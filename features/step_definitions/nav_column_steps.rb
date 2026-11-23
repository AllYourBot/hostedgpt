# frozen_string_literal: true

# Steps for the nav column, mirroring test/system/messages/nav_column_test.rb.

When("I click the conversation title {string}") do |title|
  # The sidebar's conversations load in a lazy turbo frame; asserting the text
  # first waits for that frame to finish rendering (the system test's skip
  # comment documents this: clicking mid-render silently misbehaves). The
  # click dispatches through JS with the recorded first-sign-in caveat:
  # headless Chrome drops native mouse input for clicks that navigate on the
  # first signed-in scenario, and the synthetic dispatch drives the same link
  # and Turbo navigation.
  assert_text title
  link = find("a[data-role='title']", text: title)
  page.execute_script("arguments[0].click()", link)
end

Given("I visit my first assistant's new message page") do
  visit new_assistant_message_path(users(:keith).assistants.ordered.first)
end

Then("I am on version 1 of the {string} conversation") do |fixture|
  conversation = conversations(fixture.to_sym)
  assert_current_path conversation_messages_path(conversation, version: 1)
end

Then("the {string} conversation's first message is displayed") do |fixture|
  conversation = conversations(fixture.to_sym)
  assert_first_message conversation.messages.ordered.first
end

Then("the plus icon stays hidden until the Assistants heading is hovered") do
  plus = find("#nav-scrollable a[data-role='new-assistant']", visible: :all)
  refute plus.find(".icon", visible: :all).visible?, "The plus icon should stay hidden until the Assistants heading is hovered"
end

When("I hover the Assistants heading") do
  find_link(I18n.t("app.navigation.assistants")).hover
end

Then("the plus icon shows its tooltip") do
  plus = find("#nav-scrollable a[data-role='new-assistant']", visible: :all)
  assert_shows_tooltip plus, I18n.t("app.settings.assistants.menu.new")
end

When("I click the plus icon") do
  plus = find("#nav-scrollable a[data-role='new-assistant']", visible: :all)
  click_element plus
end

Then("the first assistant is selected in the nav") do
  assert_selected_assistant users(:keith).assistants.ordered.first
end

Then("the {string} conversation's assistant is selected in the nav") do |fixture|
  assert_selected_assistant conversations(fixture.to_sym).assistant
end

Then("the nav column is visible") do
  assert_visible "nav"
end

Then("the nav column is hidden") do
  assert_hidden "nav"
end

Then("the left handle is shown with its {string} tooltip") do |tooltip|
  assert_visible "#left-handle"
  assert_shows_tooltip "#left-handle", tooltip
end

Then("the right handle is shown with its {string} tooltip") do |tooltip|
  assert_visible "#right-handle"
  assert_shows_tooltip "#right-handle", tooltip
end

Then("the left handle is hidden") do
  assert_hidden "#left-handle"
end

Then("the right handle is hidden") do
  assert_hidden "#right-handle"
end

Then("the left handle is shown") do
  assert_visible "#left-handle"
end

Then("the right handle is shown") do
  assert_visible "#right-handle"
end

When("I click the sidebar handle") do
  click_element "#handle"
end

When("I close the sidebar") do
  click_element "#handle"
  sleep 0.3
  assert_hidden "nav"
end

When("I open the sidebar") do
  click_element "#handle"
  assert_visible "nav"
end

When("I refresh the page") do
  visit current_path
end

When("I press the keyboard shortcut {string}") do |keys|
  send_keys keys
end

When("I visit the greeting conversation's show page") do
  conversation_path = conversation_messages_path(conversations(:greeting), version: 1)
  visit conversation_path
  assert_current_path conversation_path
end

When("I click the first assistant's name in the nav") do
  assistant1 = users(:keith).assistants.ordered.first
  click_text assistant1.name, match: :first
end

When("I hover the second assistant and click its new-conversation pencil") do
  assistant2 = users(:keith).assistants.ordered.second
  second_assistant_container = all("#assistants [data-role='assistant']", visible: :false)[1]
  second_assistant_container.hover
  pencil_on_second_assistant = all("#assistants a[data-role='new']", visible: :false)[1]
  assert_shows_tooltip pencil_on_second_assistant, "New"
  click_element pencil_on_second_assistant
  @second_assistant = assistant2
end

Then("I am on the second assistant's new message page") do
  assert_current_path new_assistant_message_path(@second_assistant)
end

Given("Samantha is renamed to a very long name") do
  @long_name_assistant = assistants(:samantha)
  @long_name_assistant.update!(name: "Samantha the very helpful personal assistant with a long name")
end

Given("I am on her new message page") do
  visit new_assistant_message_path(@long_name_assistant)
  assert_selected_assistant @long_name_assistant
end

Then("her name truncates in the nav") do
  name = find("#assistant_#{@long_name_assistant.id} a[data-role='name']")
  assert_true "the name should be truncated" do
    name.evaluate_script("this.querySelector('.truncate').scrollWidth > this.querySelector('.truncate').clientWidth")
  end
end

Then("her context files icon is not cut off") do
  name = find("#assistant_#{@long_name_assistant.id} a[data-role='name']")
  assert_true "the context files icon should not be cut off" do
    name.evaluate_script("this.querySelector(\"[data-role='context-files']\").getBoundingClientRect().right <= this.getBoundingClientRect().right")
  end
end

Then("hovering her name shows the context files popout") do
  name = find("#assistant_#{@long_name_assistant.id} a[data-role='name']")
  name.hover
  assert_selector ".overflow-expand-popout [data-role='context-files']", visible: :all
end
