# frozen_string_literal: true

# Steps for the conversation messages page, mirroring
# test/system/conversations/messages_test.rb.

Given("the user has 15 conversations") do
  15.times { users(:keith).conversations.create!(assistant: assistants(:samantha), title: "Conversation #{_1 + 1}") }
end

Given("the user has 6 extra assistants") do
  6.times { users(:keith).assistants.create!(name: "Extra Assistant #{_1 + 1}", language_model: language_models(:gpt_4o)) }
end

Given("the greeting conversation has an unanswered question") do
  conversations(:greeting).messages.create! role: :user, content_text: "Are you still there?", assistant: conversations(:greeting).assistant
end

Given("its latest message is a failed blank response") do
  latest_message.update! content_text: "(I received a blank response.)", failed_at: Time.current
end

Given("the greeting conversation's latest message is truncated") do
  latest_message.update! truncated_at: Time.current
end

Given("the greeting conversation has an AskUser exchange") do
  call = { type: "function", id: "call_ask", function: { name: "askuser_ask_user", arguments: { question: "Which plan?", choices: ["Free", "Pro"] } } }
  conversations(:greeting).messages.create!(role: :assistant, content_text: nil, assistant: conversations(:greeting).assistant, content_tool_calls: [call], processed_at: Time.current, version: :latest)
  conversations(:greeting).messages.create!(role: :tool, assistant: conversations(:greeting).assistant, tool_call_id: "call_ask", content_tool_calls: call,
    content_text: { message_to_user: "Which plan?", choices: ["Free", "Pro"] }.to_json, processed_at: Time.current, version: :latest)
end

Given("the greeting conversation has a stub assistant reply") do
  @new_message = conversations(:greeting).messages.create! assistant: conversations(:greeting).assistant, content_text: "Stub: ", role: :assistant
end

When("I re-open the greeting conversation") do
  visit_and_scroll_wait conversation_messages_path(conversations(:greeting))
end

Then("the clipboard icon on the last message shows its tooltip") do
  assert_shows_tooltip hover_last_message.find_role("clipboard"), "Copy"
end

When("I copy the last message") do
  @clipboard = hover_last_message.find_role("clipboard")
  @clipboard.click
end

Then("the clipboard tooltip says {string}") do |text|
  assert_shows_tooltip @clipboard, text
end

When("I move to the regenerate icon") do
  hover_last_message.find_role("regenerate").hover
end

Then("the regenerate icon on the last message shows its tooltip") do
  assert_shows_tooltip hover_last_message.find_role("regenerate"), "Regenerate"
end

When("I open the regenerate menu on the last message") do
  hover_last_message.find_role("regenerate").click
end

Then("the menu lists both assistants") do
  existing_assistant = conversations(:greeting).assistant
  new_assistant = other_assistant_for(users(:keith), existing_assistant)

  assert_text "Using #{existing_assistant.name}"
  assert_text "Using #{new_assistant.name}"
end

Then("the last message is from the current assistant") do
  assert_equal conversations(:greeting).assistant.name, last_message.find_role("from").text
end

When("I pick the other assistant from the menu") do
  new_assistant = other_assistant_for(users(:keith), conversations(:greeting).assistant)
  click_text "Using #{new_assistant.name}"
end

Then("the last message is from the other assistant") do
  new_assistant = other_assistant_for(users(:keith), conversations(:greeting).assistant)

  assert_true do
    last_message.find_role("from").text == new_assistant.name
  end
end

Then("I am on version 2 of the conversation") do
  assert_current_path conversation_messages_path(conversations(:greeting), version: 2)
end

Then("no assistant in the regenerate menu is clipped out of the messages pane") do
  top_assistant = users(:keith).assistants.ordered.first
  assert_text "Using #{top_assistant.name}"

  clipped = page.evaluate_script(<<~JS)
    (() => {
      const messages = document.getElementById("messages").getBoundingClientRect()
      return [...document.querySelectorAll("#messages menu.dropdown-content button")].filter((button) => {
        button.scrollIntoView({ block: "nearest" })
        const rect = button.getBoundingClientRect()
        return rect.top < messages.top || rect.bottom > messages.bottom
      }).map((button) => button.textContent.trim())
    })()
  JS
  assert_empty clipped, "Every assistant in the regenerate menu should scroll into view inside the messages pane"
end

Then("picking the first assistant in the menu regenerates with it") do
  top_assistant = users(:keith).assistants.ordered.first
  click_text "Using #{top_assistant.name}"

  assert_true "Regenerating with the first assistant in the menu should work" do
    last_message.find_role("from").text == top_assistant.name
  end
end

Then("a retry button is offered without hovering") do
  retry_button = last_message.find_role("retry-button")
  assert retry_button.visible?, "A failed message should offer Retry without having to hover it"
end

When("I click retry") do
  last_message.find_role("retry-button").click
end

Then("clicking retry replaces the failed reply") do
  assert_no_text "(I received a blank response.)" # the failed reply is replaced by a fresh one
end

Then("a continue button is offered without hovering") do
  continue_button = last_message.find_role("continue-button")
  assert continue_button.visible?, "A cut-off reply should offer Continue without having to hover it"
end

When("I click continue") do
  last_message.find_role("continue-button").click
end

Then("clicking continue asks the assistant to keep going") do
  assert_true "Continue should send a follow-up message asking the assistant to keep going" do
    find_messages[-2].text.include?("Continue")
  end
end

Then("no continue buttons remain") do
  assert_selector "[data-role='continue']", count: 0
end

Then("the choices show as buttons without hovering") do
  assert_text "Which plan?"
  pro = last_message.find("[data-role='ask-user-choice']", text: "Pro")
  assert pro.visible?, "The choices should show as buttons without hovering"
end

When("I click the Pro choice") do
  last_message.find("[data-role='ask-user-choice']", text: "Pro").click
end

Then("clicking Pro answers the question") do
  assert_true "Clicking Pro should send Pro as the user's answer" do
    find_messages[-2].text.include?("Pro")
  end
end

Then("no ask-user prompts remain") do
  assert_selector "[data-role='ask-user']", count: 0
end

Then("retry stays hidden while the stream is still expected") do
  refute last_message.find_role("retry").visible?, "Retry should stay hidden while we're still waiting on the stream"
end

Then("the thinking indicator is showing") do
  assert last_message.find_role("thinking").visible?
end

When("the stream watchdog is shortened to 0.2 seconds") do
  page.execute_script("arguments[0].dataset.streamWatchdogSecondsValue = '0.2'", last_message.find_role("inner-message"))
end

Then("retry appears once the stream has gone quiet") do
  assert_true "Retry should appear once the stream has gone quiet for too long" do
    last_message.find_role("retry").visible?
  end
end

Then("the thinking indicator gives way to retry") do
  refute last_message.find_role("thinking").visible?, "The thinking indicator should give way to the Retry button"
end

Then("submitting {string} with ENTER inserts two new messages with morphing") do |text|
  assert_page_morphed do
    assert_scrolled_down do
      send_keys text
      send_keys "enter"

      assert_true "The last user message should contain the submitted text" do
        len = find_messages.length
        find_messages[len-2].text.include?(text)
      end
    end
  end
end

Then("the last message shows the stub content") do
  assert last_message.text.include?("Stub:"), "The last message should have contained the submitted text"
end

Then("the AI reply streams its full content with morphing and scrolling") do
  assert_page_morphed do
    assert_scrolled_down do
      @new_message.content_text = "The quick brown fox jumped over the lazy dog and this line needs to wrap to scroll. " +
                                  "But it was not long enough so I'm adding more text on this second line to ensure it."
      GetNextAIMessageJob.broadcast_updated_message(@new_message)

      assert_true "The last message should have contained the submitted text but it contains '#{last_message.text}'", wait: 10 do
        last_message.text.include?("The quick brown")
      end
      @new_message.save!
    end
  end
end

Given("I am on the ruby version conversation") do
  visit_and_scroll_wait conversation_messages_path(conversations(:ruby_version))
end

def latest_message
  conversations(:greeting).latest_message_for_version(:latest)
end

def other_assistant_for(user, existing_assistant)
  user.assistants.ordered.where.not(id: existing_assistant.id).first
end
