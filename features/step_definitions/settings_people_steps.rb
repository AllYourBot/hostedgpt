# frozen_string_literal: true

# Steps for the settings people page, mirroring
# test/system/settings/people_test.rb.

Given("I am signed in as the registered keith person") do
  @settings_person = people(:keith_registered)
  sign_in_as @settings_person
end

Given("I am on the settings person edit page") do
  visit edit_settings_person_path
end

Given("the Google SDK reauthentication always succeeds") do
  # The settings page re-authenticates Google credentials on load; the system
  # test stubs this for the whole test so no real token endpoint is hit.
  stub_google_sdk_reauthentication
end

When("I update my email and name appending \"-2\" and set the password") do
  fill_in "Email", with: "#{@settings_person.email}-2"
  fill_in "First name", with: "#{@settings_person.user.first_name}-2"
  fill_in "Last name", with: "#{@settings_person.user.last_name}-2"
  fill_in "Password", with: "secret"

  click_text "Save"
end

When("I update my email and name appending \"-2\" without a password") do
  fill_in "Email", with: "#{@settings_person.email}-2"
  fill_in "First name", with: "#{@settings_person.user.first_name}-2"
  fill_in "Last name", with: "#{@settings_person.user.last_name}-2"

  click_text "Save"
end

Then("I see the {string} alert") do |text|
  assert_alert text
end

Then("I stay on the settings person edit page") do
  assert_current_path edit_settings_person_path
end

Then("the person's email and name are updated") do
  expected_email = "#{@settings_person.email}-2"
  expected_first_name = "#{@settings_person.user.first_name}-2"
  expected_last_name = "#{@settings_person.user.last_name}-2"

  person = @settings_person.reload
  assert_equal expected_email, person.email
  assert_equal expected_first_name, person.user.first_name
  assert_equal expected_last_name, person.user.last_name
end

Then("the disconnect Gmail control is offered") do
  assert_selector "label[for=person_disconnect_gmail]"
end

When("I disconnect Gmail confirming the dialog") do
  accept_confirm { find("label[for=person_disconnect_gmail]").click }
end

Then("the disconnect Gmail control is no longer offered") do
  assert_no_selector "label[for=person_disconnect_gmail]"
end

Then("the disconnect Google Tasks control is offered") do
  assert_selector "label[for=person_disconnect_google_tasks]"
end

Then("Gmail is no longer connected while Google Tasks still is") do
  assert_nil @settings_person.user.reload.gmail_credential, "Gmail should no longer be connected"
  assert @settings_person.user.google_tasks_credential.present?, "Google Tasks should still be connected"
end

When("I follow {string} within the settings menu") do |text|
  within("section#menu") { click_text text }
end

Then("the settings menu has no assistant avatars") do
  assert_no_selector "section#menu picture"
end
