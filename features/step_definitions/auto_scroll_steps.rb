# frozen_string_literal: true

# Steps for the conversation auto-scroll behavior, mirroring
# test/system/conversations/messages/auto_scroll_test.rb.

Then("the scroll button is hidden") do
  assert_hidden "#scroll-button", "Page should have auto-scrolled to the bottom and hidden the scroll button."
end

Then("the scroll button is visible") do
  assert_visible "#scroll-button"
end

When("I scroll up to the second message") do
  assert_scrolled_up { scroll_to find_messages.second }
end

When("I scroll up to the first message") do
  assert_scrolled_up { scroll_to first_message }
end

When("I scroll back down to the last message") do
  assert_scrolled_to_bottom { scroll_to last_message }
end

Then("the page is scrolled to the bottom") do
  assert_at_bottom
end

When("I click the scroll button") do
  assert_scrolled_to_bottom { click_element "#scroll-button button" }
end

When("I submit {string} with ENTER and stay at the bottom") do |text|
  assert_stays_at_bottom "section #messages" do
    send_keys text
    send_keys "enter"

    assert_true "The last user message should have contained the submitted text" do
      len = find_messages.length
      find_messages[len-2].text.include?(text)
    end
  end
end

Then("two new messages contain the submission") do
  assert_true "The last user message should have contained the submitted text" do
    len = find_messages.length
    find_messages[len-2].text.include?("Watch me appear")
  end
end

When("the stub reply streams while staying at the bottom") do
  assert_stays_at_bottom "section #messages" do
    @new_message.content_text = "The quick brown fox jumped over the lazy dog and this line needs to wrap to scroll. " +
                                "But it was not long enough so I'm adding more text on this second line to ensure it."
    GetNextAIMessageJob.broadcast_updated_message(@new_message)
    assert_true "The last message should have contained the submitted text", wait: 10 do
      last_message.text.include?("The quick brown")
    end
  end
end

Then("the streamed content is displayed") do
  assert_true "The last message should have contained the submitted text", wait: 10 do
    last_message.text.include?("The quick brown")
  end
end

When("the browser resizes while staying at the bottom") do
  assert_stays_at_bottom do
    resize_browser_to(1400, 700)
  end
end

Then("resizing the browser does not auto-scroll the conversation") do
  assert_did_not_scroll do
    resize_browser_to(1400, 700)
  end
end
