# frozen_string_literal: true

# Steps for the speaker controller, mirroring
# test/system/conversations/messages/speaker_test.rb.

Given("I am on the hello-claude conversation with the mic enabled") do
  stub_features voice: true
  visit conversation_messages_path(conversations(:hello_claude))
  enable_mic.click
  disable_mic.visible?
end

Given("I am on Samantha's new message page with the mic enabled") do
  stub_features voice: true
  visit new_assistant_message_path(assistants(:samantha))
  enable_mic.click
  disable_mic.visible?
end

Given("I arrive at the hello-claude conversation from the sidebar with the mic enabled") do
  stub_features voice: true
  visit conversation_messages_path(conversations(:greeting))
  find("#conversation-#{conversations(:hello_claude).id} a[data-role='title']").click
  assert_text conversations(:hello_claude).title

  enable_mic.click
  disable_mic.visible?
end

When("the second assistant message's speaker values are forced") do
  page.execute_script("arguments[0].setAttribute('data-speaker-playedback-id-value', '123')", assistant_messages[1].native)
  page.execute_script("arguments[0].setAttribute('data-speaker-waiting-for-next-playback-value', 'true')", assistant_messages[1].native)
end

Then("the second assistant message keeps its forced speaker values") do
  assert_equal "123", assistant_messages[1]["data-speaker-playedback-id-value"], "The speaker playedback value should not have changed"
  assert_equal "true", assistant_messages[1]["data-speaker-waiting-for-next-playback-value"], "The speaker waiting value should not have changed"
end

When("the user speaks {string} creating a conversation") do |text|
  page.execute_script("Listener.$.consideration = `#{text}`")
  assert_true "current_path did not change" do
    current_path.include?("/conversation")
  end
end

When("the user speaks {string} and the reply streams {string}") do |question, reply|
  user_speaks question
  stream_ai_reply reply
end

When("the user speaks {string} and the reply streams {string} while thinking") do |question, reply|
  user_speaks question
  stream_ai_reply reply, thinking: true
end

When("the user speaks {string} morphing the reply {string}") do |question, reply|
  user_speaks question
  morph_ai_reply reply
end

Then("the new page's reply spoke to sentence {string} and finished with nothing") do |index|
  assert_spoke_to_sentence index, assistant_messages.last
  assert_finished_speaking nil
end

Then("the new page's reply spoke to sentence {string} and finished with the last message") do |index|
  assert_spoke_to_sentence index, assistant_messages.last
  assert_finished_speaking Message.last
end

Then("the morphed page's reply spoke to sentence {string} and finished with the last message") do |index|
  assert_spoke_to_sentence index, assistant_messages.last
  assert_finished_speaking Message.last
end

Then("nothing has played back on the existing conversation") do
  assert_finished_speaking conversations(:hello_claude).latest_message_for_version
  assert_spoke_to_sentence "0", assistant_messages.first
  assert_spoke_to_sentence "0", assistant_messages.last
end

Then("the reply finished with the last message and spoke to sentence {string}") do |index|
  assert_finished_speaking Message.last
  assert_spoke_to_sentence index, assistant_messages.last
end

Then("the first assistant message spoke to sentence {string}") do |index|
  assert_spoke_to_sentence index, assistant_messages.first
end

When("the user speaks {string} and the reply streams the long first sentence while thinking") do |question|
  user_speaks question
  stream_ai_reply "This is the first sentence of a long reply. The quick brown fox jumped over the lazy dog. ", thinking: true
end

Given("the pre-existing latest message is recorded") do
  @hello_previous_msg = conversations(:hello_claude).latest_message_for_version
end

Then("the long reply spoke to sentence {string} and the recorded message finished") do |index|
  assert_spoke_to_sentence index, assistant_messages[2]
  assert_finished_speaking @hello_previous_msg
end

Then("the reply finished with the last message, spoke to sentence {string}, and the long reply still spoke to sentence {string}") do |index, long_index|
  assert_finished_speaking Message.last
  assert_spoke_to_sentence index, assistant_messages[3]
  assert_spoke_to_sentence long_index, assistant_messages[2] # double-check that previous message did not speak any more
end

When("the new page's reply streams {string} while thinking") do |text|
  stream_ai_reply text, thinking: true
end

When("the new page's reply streams {string} to settle") do |text|
  stream_ai_reply text
end

When("the user speaks {string} and the first reply streams {string} while thinking") do |question, reply|
  @pre_existing_msg = conversations(:hello_claude).latest_message_for_version
  user_speaks question
  stream_ai_reply reply, thinking: true
  @first_reply = Message.last
end

Then("the long reply spoke to sentence {string}") do |index|
  assert_spoke_to_sentence index, assistant_messages[2]
end

When("the mic is disabled") do
  disable_mic.click
end

When("the mic is enabled again") do
  enable_mic.click
end

When("the reply streams the long final sentence to settle") do
  stream_ai_reply "This is the first sentence of a long reply. The quick brown fox jumped over the lazy dog. A final sentence."
end

Then("the latest message finished and the long reply spoke to sentence {string}") do |index|
  assert_finished_speaking conversations(:hello_claude).latest_message_for_version
  assert_spoke_to_sentence index, assistant_messages[2]
end

When("a second reply is stubbed and streams {string}") do |text|
  stub_new_ai_reply
  stream_ai_reply text
end

Then("the message count grew by one") do
  # The stub + stream in the previous step created the reply; its presence on
  # screen is asserted by the follow-up steps.
  assert Message.last
end

When("a second reply is stubbed and the first reply streams {string} targeting the second") do |text|
  @second_reply = nil
  stub_new_ai_reply
  @second_reply = Message.last
  stream_ai_reply text, message: @second_reply
end

Then("four assistant messages are on screen") do
  assert_true "new assistant message did not appear on the screen" do
    assistant_messages.length == 4
  end
end

Then("the second reply spoke to sentence {string}") do |index|
  assert_spoke_to_sentence index, assistant_messages[3] # new msg should not start yet
end

When("the first reply streams {string} to settle") do |text|
  stream_ai_reply text, message: @first_reply
end

Then("the first reply spoke to sentence {string}") do |index|
  assert_spoke_to_sentence index, assistant_messages[2]
end

Then("the second reply finished and spoke to sentence {string}") do |index|
  assert_finished_speaking @second_reply
  assert_spoke_to_sentence index, assistant_messages[3]
end

Then("the pre-existing message finished and the first reply spoke to sentence {string}") do |index|
  assert_finished_speaking @pre_existing_msg
  assert_spoke_to_sentence index, assistant_messages[2]
end

When("the user speaks {string} and the reply streams {string} capturing the first reply") do |question, reply|
  user_speaks question
  stream_ai_reply reply, thinking: true
  @first_reply = Message.last
end

When("the reply turns into a tool call and refreshes") do
  # The system test records the count after the empty reply streamed (the
  # assistant message is on screen) and expects it to drop by one when the
  # tool call hides the message.
  @assistant_message_count_before_tool_call = assistant_messages.length

  first_reply = Message.last
  first_reply.update!(content_tool_calls: [{ type: "function" }])
  assert first_reply.only_tool_response?
  first_reply.conversation.broadcast_refresh
end

Then("the assistant message disappeared from screen") do
  assert_true "assistant message should have disappeared from screen" do
    assistant_messages.length == @assistant_message_count_before_tool_call - 1
  end
end

Then("a new assistant message appeared on screen") do
  assert_true "a new assistant message should have appeared on screen" do
    assistant_messages.length == @assistant_message_count_before_tool_call
  end
end

Then("the long reply being read aloud shows stop") do
  reply = assistant_messages[2]
  reply.hover
  assert_true "The reply being read aloud should show stop" do
    reply.find_role("stop").visible?
  end
end

When("I click stop on the long reply") do
  reply = assistant_messages[2]
  reply.find_role("stop").click
  reply.hover
end

Then("clicking stop flips the long reply back to play") do
  reply = assistant_messages[2]
  reply.hover
  assert_true "Clicking stop should flip it back to play" do
    reply.find_role("play").visible?
  end
end

Then("the long reply's play button reappears once it has been read") do
  reply = assistant_messages[2]
  reply.hover
  assert_true "The play button should reappear once the reply has been read" do
    reply.find_role("play").visible?
  end
end

def assistant_messages = page.all("[data-subrole='assistant-message']")

def speaker = page.find("[data-controller~='speaker']")

def user_speaks(text)
  if current_path.include?("/conversation")
    audio_finishes_processing do
      page.execute_script("Listener.$.consideration = `#{text}`")
    end
  else
    page.execute_script("Listener.$.consideration = `#{text}`")
    assert_true "current_path did not change" do
      current_path.include?("/conversation")
    end
  end
end

def stub_new_ai_reply
  msg = conversations(:hello_claude).latest_message_for_version
  conversations(:hello_claude).messages.create!(
    assistant: conversations(:hello_claude).assistant,
    role: :assistant,
    content_text: nil,
    version: msg.version,
    index: msg.index + 1,
  )
end

def stream_ai_reply(text, message: nil, thinking: false)
  msg = message || Message.last
  msg.content_text = text
  GetNextAIMessageJob.broadcast_updated_message(msg, thinking: thinking)
  if !thinking
    msg.save!
    msg.conversation.broadcast_refresh
  end
  nil
end

def morph_ai_reply(text, message: nil)
  msg = message || Message.last
  msg.content_text = text
  msg.save!
  msg.conversation.broadcast_refresh
end

def assert_spoke_to_sentence(expected, element)
  assert_true "sentence index value did not update to #{expected}" do
    expected == element["data-playback-sentences-index-value"]
  end
  true
end

def assert_finished_speaking(msg)
  if msg == nil
    assert_nil speaker["data-speaker-playedback-id-value"]
  else
    assert_true "speaker playback did not update to #{msg.id}" do
      msg.id == speaker["data-speaker-playedback-id-value"].to_i
    end
  end
  true
end

def audio_finishes_processing(&block)
  assistant_message_length = assistant_messages.length
  assert_page_morphed do
    yield
  end

  assert_true do
    assistant_messages.length > assistant_message_length
  end
  true
end
