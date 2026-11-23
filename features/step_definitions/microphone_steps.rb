# frozen_string_literal: true

# Steps for the composer microphone, mirroring
# test/system/messages/composer/microphone_test.rb.

Given("I am on Samantha's new message page") do
  visit new_assistant_message_path(assistants(:samantha))
end

Then("the composer has no mic enable button") do
  assert_no_selector "#composer #microphone-enable"
end

Then("the mic enable button is visible") do
  assert enable_mic.visible?
end

Then("the mic enable button is hidden") do
  refute enable_mic.visible?
end

Then("the mic disable button is visible") do
  assert disable_mic.visible?
end

Then("the mic disable button is hidden") do
  refute disable_mic.visible?
end

When("I click the mic enable button") do
  enable_mic.click
end

When("I click the mic disable button") do
  disable_mic.click
end

When("I press the mic keyboard shortcut") do
  send_keys "meta+m"
end

When("I set the composer value to {string} and click the composer overlay") do |text|
  page.execute_script("document.querySelector(`#composer textarea`).value = '#{text}'")

  click_element "#composer-overlay"
end

When("the listener considers {string}") do |text|
  page.execute_script("Listener.$.consideration = '#{text}'")
end

Then("the {string} message was spoken") do |text|
  assert Message.user.find_by!(content_text: text).spoken?
end

Then("the {string} message was not spoken") do |text|
  refute Message.user.find_by!(content_text: text).spoken?
end

When("I open the attachment conversation from the nav") do
  find("#conversation-#{conversations(:attachment).id} a[data-role='title']").click
end

Then("the listener is disabled after switching conversations") do
  assert_true("The listener should be disabled after switching conversations") { page.evaluate_script("Listener.disabled") }
end

Then("the composer shows the mic enable button") do
  assert_selector "#composer [data-composer-target='microphoneEnable'] button"
end

Then("the composer shows the mic disable button") do
  assert_selector "#composer [data-composer-target='microphoneDisable']"
end

Then("the composer hides the mic disable button") do
  assert_no_selector "#composer [data-composer-target='microphoneDisable']"
end

Then("the listener stays enabled after sending a spoken message") do
  refute page.evaluate_script("Listener.disabled"), "The listener should stay enabled after sending a spoken message"
end
