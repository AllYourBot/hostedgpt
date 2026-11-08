require "application_system_test_case"

class ConversationMessagesTest < ApplicationSystemTestCase
  include NavigationHelper

  setup do
    15.times { users(:keith).conversations.create!(assistant: assistants(:samantha), title: "Conversation #{it+1}") }

    @user = users(:keith)
    login_as @user
    @conversation = conversations(:greeting)
    visit_and_scroll_wait conversation_messages_path(@conversation)
  end

  test "clipboard icon shows tooltip" do
    msg = hover_last_message
    assert_shows_tooltip msg.find_role("clipboard"), "Copy"
  end

  test "clicking clipboard icon changes the tooltip & icon to check, mousing out changes it back" do
    msg = hover_last_message
    clipboard = msg.find_role("clipboard")

    clipboard.click
    assert_shows_tooltip clipboard, "Copied!"

    msg.find_role("regenerate").hover
    assert_shows_tooltip clipboard, "Copy"
  end

  test "regenerate icon shows tooltip" do
    msg = hover_last_message
    assert_shows_tooltip msg.find_role("regenerate"), "Regenerate"
  end

  test "clicking regenerate icon shows menu and triggers re-generation" do
    existing_assistant = @conversation.assistant
    new_assistant = @user.assistants.ordered.where.not(id: existing_assistant.id).first

    msg = hover_last_message
    regenerate = msg.find_role("regenerate")

    regenerate.click
    assert_text "Using #{existing_assistant.name}"
    assert_text "Using #{new_assistant.name}"

    assert_equal existing_assistant.name, last_message.find_role("from").text

    click_text "Using #{new_assistant.name}"

    assert_true do
      last_message.find_role("from").text == new_assistant.name
    end
    assert_current_path conversation_messages_path(@conversation, version: 2)
  end

  test "regenerate menu keeps every assistant reachable when it is taller than the space above a short conversation" do
    6.times { @user.assistants.create!(name: "Extra Assistant #{it + 1}", language_model: language_models(:gpt_4o)) }
    top_assistant = @user.assistants.ordered.first
    visit_and_scroll_wait conversation_messages_path(conversations(:ruby_version))

    hover_last_message.find_role("regenerate").click
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

    click_text "Using #{top_assistant.name}"
    assert_true "Regenerating with the first assistant in the menu should work" do
      last_message.find_role("from").text == top_assistant.name
    end
  end

  test "a failed response shows a retry button which regenerates the reply" do
    ask_a_question
    latest_message.update! content_text: "(I received a blank response.)", failed_at: Time.current
    visit_and_scroll_wait conversation_messages_path(@conversation)

    retry_button = last_message.find_role("retry-button")
    assert retry_button.visible?, "A failed message should offer Retry without having to hover it"

    retry_button.click

    assert_no_text "(I received a blank response.)" # the failed reply is replaced by a fresh one
    assert_current_path conversation_messages_path(@conversation, version: 2)
  end

  test "a reply cut off at the token limit shows a continue button which asks the assistant to keep going" do
    latest_message.update! truncated_at: Time.current
    visit_and_scroll_wait conversation_messages_path(@conversation)

    continue_button = last_message.find_role("continue-button")
    assert continue_button.visible?, "A cut-off reply should offer Continue without having to hover it"

    continue_button.click

    assert_true "Continue should send a follow-up message asking the assistant to keep going" do
      find_messages[-2].text.include?("Continue")
    end
    assert_selector "[data-role='continue']", count: 0
  end

  test "an AskUser question shows its choices as buttons and clicking one answers it" do
    call = { type: "function", id: "call_ask", function: { name: "askuser_ask_user", arguments: { question: "Which plan?", choices: ["Free", "Pro"] } } }
    @conversation.messages.create!(role: :assistant, content_text: nil, assistant: @conversation.assistant, content_tool_calls: [call], processed_at: Time.current, version: :latest)
    @conversation.messages.create!(role: :tool, assistant: @conversation.assistant, tool_call_id: "call_ask", content_tool_calls: call,
      content_text: { message_to_user: "Which plan?", choices: ["Free", "Pro"] }.to_json, processed_at: Time.current, version: :latest)
    visit_and_scroll_wait conversation_messages_path(@conversation)

    assert_text "Which plan?"
    pro = last_message.find("[data-role='ask-user-choice']", text: "Pro")
    assert pro.visible?, "The choices should show as buttons without hovering"

    pro.click

    assert_true "Clicking Pro should send Pro as the user's answer" do
      find_messages[-2].text.include?("Pro")
    end
    assert_selector "[data-role='ask-user']", count: 0
  end

  test "a stalled response shows a retry button once the stream goes quiet" do
    ask_a_question # the assistant's reply is created blank and is never filled in
    visit_and_scroll_wait conversation_messages_path(@conversation)
    msg = last_message

    refute msg.find_role("retry").visible?, "Retry should stay hidden while we're still waiting on the stream"
    assert msg.find_role("thinking").visible?

    page.execute_script("arguments[0].dataset.streamWatchdogSecondsValue = '0.2'", msg.find_role("inner-message"))

    assert_true "Retry should appear once the stream has gone quiet for too long" do
      msg.find_role("retry").visible?
    end
    refute msg.find_role("thinking").visible?, "The thinking indicator should give way to the Retry button"
  end

  test "submitting a message with ENTER inserts two new messages with morphing" do
    assert_page_morphed do
      assert_scrolled_down do
        send_keys "Watch me appear"
        send_keys "enter"

        assert_true "The last user message should contain the submitted text" do
          len = find_messages.length
          find_messages[len-2].text.include?("Watch me appear")
        end
      end
    end
  end

  test "when the AI replies with a message it appears with morphing" do
    @new_message = @conversation.messages.create! assistant: @conversation.assistant, content_text: "Stub: ", role: :assistant
    visit_and_scroll_wait conversation_messages_path(@conversation.id)

    assert last_message.text.include?("Stub:"), "The last message should have contained the submitted text"

    assert_page_morphed do
      assert_scrolled_down do
        @new_message.content_text = "The quick brown fox jumped over the lazy dog and this line needs to wrap to scroll. " +
                                    "But it was not long enough so I'm adding more text on this second line to ensure it."
        GetNextAIMessageJob.broadcast_updated_message(@new_message)
        sleep 5 # TODO: cannot solve a "stale element reference" bug so trying this
        assert_true "The last message should have contained the submitted text but it contains '#{last_message.text}'", wait: 10 do
          last_message.text.include?("The quick brown")
        end
        @new_message.save!
      end
    end
  end

  private

  def ask_a_question
    @conversation.messages.create! role: :user, content_text: "Are you still there?", assistant: @conversation.assistant
  end

  def latest_message = @conversation.latest_message_for_version(:latest)
end
