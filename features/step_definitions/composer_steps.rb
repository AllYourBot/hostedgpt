# frozen_string_literal: true

# Steps for the composer, mirroring test/system/messages/composer_test.rb and
# the other composer ports. Shared helpers (submit_button, find_previews)
# live here for the whole composer domain.

Then("the composer input is focused") do
  assert_active composer_selector
end

Then("the body is focused") do
  assert_active "body"
end

When("I press {string}") do |keys|
  send_keys keys
end

When("I select the greeting conversation from the nav") do
  assert_conversation_navigation_finished do
    click_text conversations(:greeting).title
  end
end

Then("the images have loaded") do
  wait_for_images_to_load
end

Then("the composer is empty") do
  assert_equal "", composer.value
end

Then("the composer holds {string}") do |text|
  assert_equal text, composer.value
end

When("I click outside the modal") do
  page.execute_script("document.querySelector('#modal-backdrop').click()") # passes a click event directly to the element
end

Then("the submit button is hidden") do
  refute submit_button.visible?
end

Then("the submit button is shown") do
  assert submit_button.visible?
end

When("I type {string} in the composer") do |text|
  send_keys text
end

When("I press enter") do
  send_keys "enter"
end

When("I click the submit button") do
  click_element submit_button
end

Then("the composer is blank") do
  assert_composer_blank
end

Then("I am on the newest conversation's messages") do
  assert_equal conversation_messages_path(users(:keith).conversations.ordered.first), current_path, "Should have redirected to newly created conversation"
end

When("I press shift+enter") do
  send_keys "shift+enter"
end

Then("the composer holds two lines") do
  assert_equal "First line\nSecond line", composer.value
end

When("I submit with enter and the conversation navigation finishes") do
  assert_conversation_navigation_finished do
    send_keys "enter"
  end
end

When("I submit {string} to the existing conversation with ENTER") do |text|
  assert_page_morphed do
    send_keys text
    send_keys "enter"
  end
end

When("I submit {string} to the existing conversation by clicking") do |text|
  assert_page_morphed do
    send_keys text
    click_element submit_button
  end
end

When("I submit {string} with morphing and scrolling") do |text|
  assert_page_morphed do
    assert_scrolled_down do
      send_keys text
      send_keys "enter"
    end
  end
end

When("the assistant reply is stubbed with {string}") do |text|
  assistant_reply = Message.last
  assistant_reply.content_text = text
  GetNextAIMessageJob.broadcast_updated_message(assistant_reply)
end

When("the conversation refreshes with a long reply") do
  assert_page_morphed do
    assert_scrolled_down do
      assistant_reply = Message.last
      assistant_reply.content_text = "Assistant reply has gotten really long so that I can ensure it wraps and the page " +
        "will need to scroll down in order to accomodate the wrapped lines. The quick brown fox jumped over the lazy dog. " +
        "The quick brown fox jumped over the lazy dog."
      assistant_reply.save!
      conversations(:greeting).broadcast_refresh_to conversations(:greeting)
    end
  end
end

When("I record the current path") do
  @recorded_path = URI.parse(current_url).path
end

Then("the path has not changed since I recorded it") do
  assert_equal @recorded_path, URI.parse(current_url).path
end

def submit_button = find("#composer #send", visible: :all)
