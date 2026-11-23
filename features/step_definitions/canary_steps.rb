# frozen_string_literal: true

# Canary steps for features/canary.feature — diagnostic-only (@wip), so helper
# breakage surfaces here instead of mid-port. Disposition (keep or delete) is
# decided when the port completes.

Given("I am on the greeting conversation") do
  visit_and_scroll_wait conversation_messages_path(conversations(:greeting))
end

Given("I am on the memorize conversation") do
  visit_and_scroll_wait conversation_messages_path(conversations(:memorize))
end

Given("I am on the javascript conversation") do
  visit_and_scroll_wait conversation_messages_path(conversations(:javascript))
end

Then("the message list has settled scrolled to the bottom") do
  assert_at_bottom
end

Then("a polled assertion waits for messages to be present") do
  assert_true "waiting for messages to appear" do
    find_messages.any?
  end
end

Then("the clipboard button on the last message shows its tooltip") do
  assert_shows_tooltip hover_last_message.find_role("clipboard"), "Copy"
end

Then("the composer can receive the active element and keyboard events") do
  click_element composer
  assert_active composer
  send_keys "esc"
end

Then("all image loaders have finished") do
  wait_for_images_to_load
end

Then("active storage fixture blobs are loaded") do
  assert ActiveStorage::Blob.count > 0, "expected active_storage fixture blobs to load"
  assert ActiveStorage::Attachment.count > 0, "expected active_storage fixture attachments to load"
end
