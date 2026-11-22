# frozen_string_literal: true

# Steps for the settings assistants pages, mirroring
# test/system/settings/assistants_test.rb.

Given("I am on the settings assistants page") do
  visit settings_assistants_path
end

Given("I am on the new settings assistant page") do
  visit new_settings_assistant_path
end

Given("I am on the settings assistant edit page for Samantha") do
  @settings_assistant = assistants(:samantha)
  visit edit_settings_assistant_path(@settings_assistant)
end

Then("each assistant renders with its service logo avatar") do
  assert_selector "#assistants picture img[src*='groq_logo']" # Groq Llama 3.3
  assert_selector "#assistants picture img[src*='openai_logo']", count: 3 # Samantha, GPT 3.5, OpenAI GPT-4o
  assert_selector "#assistants picture img[src*='claude_logo']", count: 2
  assert_selector "#assistants picture img[src*='ollama_logo']" # Qwen3 8B
  assert_equal "block", page.evaluate_script("getComputedStyle(document.querySelector('#assistants picture')).display")
end

When("I create an assistant with Samantha's details") do
  fill_in "Name", with: assistants(:samantha).name
  fill_in "Description", with: assistants(:samantha).description
  fill_in "Instructions", with: assistants(:samantha).instructions
  click_text "Save"
end

When("I update her details appending \"-2\"") do
  fill_in "Name", with: "#{@settings_assistant.name}-2"
  fill_in "Description", with: "#{@settings_assistant.description}-2"
  fill_in "Instructions", with: "#{@settings_assistant.instructions}-2"
  click_text "Save"
end

When("I set the conversation starters") do
  fill_in "Conversation starter 1", with: "What should I cook tonight?"
  fill_in "Conversation starter 2", with: "Plan my week"
end

When("I save the settings form") do
  click_text "Save"
end

When("I save the settings form again") do
  click_text "Save"
end

Then("the first conversation starter field keeps its value") do
  assert_field "Conversation starter 1", with: "What should I cook tonight?"
end

Given("I am on a new conversation with Samantha") do
  visit new_assistant_message_path(@settings_assistant)
end

When("I click the conversation starter {string}") do |starter|
  click_text starter
end

Then("the starter's question is sent as written") do
  assert_no_current_path new_assistant_message_path(@settings_assistant)
  assert @settings_assistant.messages.exists?(role: "user", content_text: "Plan my week"), "Clicking a starter should send its question as written"
end

Then("the assistant's context section is shown") do
  assert_text "Context"
end

When("I attach the test document") do
  attach_file "document[file]", Rails.root.join("test/fixtures/files/test_document.txt"), make_visible: true
end

When("I remove the uploaded document confirming the dialog") do
  accept_confirm do
    within("#context #document_#{@settings_assistant.documents.last.id}") { click_text "Remove" }
  end
end

When("I dismiss the alert") do
  find("#alerts .alert button").click
end
