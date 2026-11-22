# frozen_string_literal: true

# Steps for stubbing feature flags and settings in scenarios, backed by
# StubHelpers (persistent redefinition + config reload; an After hook unstubs).
# Mirrors the system tests' stub_features / with_assistants_page usage.

When("the assistants page feature is enabled") do
  stub_features assistants_page: true
end

When("the assistants page feature is disabled") do
  stub_features assistants_page: false
end

When("I visit the root path") do
  visit root_path
end

Then("I am on the assistants page") do
  assert_current_path root_path
end

Then("the root path redirects to a conversation page") do
  assistant = users(:keith).assistants.ordered.first
  assert_current_path new_assistant_message_path(assistant)
end

Then("the first assistant in the nav is selected") do
  assert_selected_assistant users(:keith).assistants.ordered.first
end
