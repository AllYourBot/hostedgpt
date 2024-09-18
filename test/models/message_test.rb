require "test_helper"

class MessageTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "has an associated assistant (it's through conversation)" do
    assert_instance_of Assistant, messages(:hear_me).assistant
  end

  test "has an associated conversation" do
    assert_instance_of Conversation, messages(:hear_me).conversation
  end

  # The API is not clear on when this field is used so for now our fixtures do not ever include one. If we want to attach an image to a message
  # it sounds like it's done with the Document/File model: info: https://platform.openai.com/docs/assistants/tools/knowledge-retrieval
  # and https://platform.openai.com/docs/guides/vision
  #
  # test "has associated content_document" do
  #   assert_instance_of Document, messages(:examine_this).content_document
  # end

  test "handles documents_attributes" do
    Current.user = users(:keith)
    test_file = fixture_file_upload("cat.png", "image/png")
    message = Message.create(assistant: assistants(:samantha), documents_attributes: {"0": {file: test_file}}, content_text: "Nice file")
    assert_equal 1, message.documents.length
    document = message.documents.first
    assert_equal "cat.png", document.filename
  end

  test "has an associated run" do
    assert_instance_of Run, messages(:yes_i_do).run
  end

  test "has associated user (delegated)" do
    assert_instance_of User, messages(:yes_i_do).user
  end

  test "has associated latest_assistant_message_for but can be nil" do
    assert_nil messages(:dont_know_day).latest_assistant_message_for
    assert_instance_of Conversation, messages(:im_a_bot).latest_assistant_message_for
  end

  test "has associated memories" do
    assert_instance_of Memory, messages(:hear_me).memories.first
  end

  test "content_tool_calls starts as empty hash" do
    h = {}
    assert_equal h, Message.new.content_tool_calls
  end

  test "name_for_api returns a properly formatted string" do
    assert_equal users(:keith).first_name, messages(:hear_me).name_for_api
    assert_equal "Samantha", messages(:yes_i_do).name_for_api
    assert_equal "OpenAI", messages(:popstate_event).name_for_api # strips off non-alphanumeric
    assert_nil messages(:weather_tool_result).name_for_api
  end

  test "finished? returns true if processed and missing either content_text or content_tool_calls" do
    assert messages(:weather_tool_call).finished?
    messages(:weather_tool_call).content_tool_calls = []
    refute messages(:weather_tool_call).finished?

    assert messages(:weather_explained).finished?
    messages(:weather_explained).content_text = nil
    refute messages(:weather_explained).finished?
  end

  test "create without setting Current or conversation raises" do
    assert_raises ActiveRecord::RecordInvalid do
      Message.create!(content_text: "Hello")
    end
  end

  test "minimal create works when Current is set" do
    Current.user = users(:keith)

    assert_nothing_raised do
      Message.create!(assistant: assistants(:samantha), content_text: "Hello")
    end

    assert_equal assistants(:samantha), Message.last.assistant
    assert_not_nil Message.last.conversation
    assert_equal users(:keith), Message.last.conversation.user
  end

  test "creating a tool message fails without a tool_call_id" do
    assert_raises ActiveRecord::RecordInvalid do
      conversations(:weather).messages.create!(
        assistant: assistants(:samantha),
        role: :tool,
        content_text: "tool response",
      )
    end
  end

  test "creating a tool message fails without a content_text" do
    assert_raises ActiveRecord::RecordInvalid do
      conversations(:weather).messages.create!(
        assistant: assistants(:samantha),
        role: :tool,
        tool_call_id: "tool_1234",
      )
    end
  end

  test "creating a tool message succeeds with both tool_call_id and content_text" do
    assert_nothing_raised do
      conversations(:weather).messages.create!(
        assistant: assistants(:samantha),
        role: :tool,
        content_text: "tool response",
        tool_call_id: "tool_1234",
      )
    end
  end

  test "creating a message with a conversation and Current.user set fails if conversation is not owned by the user" do
    Current.user = users(:rob)
    assistant = users(:rob).assistants.first
    conversation_owned_by_someone_else = users(:keith).conversations.first

    assert_raises ActiveRecord::RecordInvalid do
      Message.create!(
        assistant: assistant,
        conversation: conversation_owned_by_someone_else,
        content_text: "This should fail"
      )
    end
  end

  test "creating a message with a conversation and Current.user succeeds when conversation is owned by the user" do
    Current.user = users(:rob)
    assistant = users(:rob).assistants.first
    conversation = users(:rob).conversations.first

    assert_nothing_raised do
      message = Message.create!(
        assistant: assistant,
        conversation: conversation,
        content_text: "This works since Conversation is owned by Current.user"
      )
      assert_equal Current.user, message.conversation.user
    end
  end

  test "creating a message with conversation user that does not match the assistant user succeeds when Current.user is not set" do
    assistant = users(:rob).assistants.first
    conversation = users(:keith).conversations.first
    Current.user = nil

    assert_not_equal assistant.user, conversation.user

    assert_nothing_raised do
      message = Message.create!(
        assistant: assistant,
        conversation: conversation,
        content_text: "This works since Current.user not set"
      )
    end
  end

  test "creating a message with a different assistant and Current.user set fails if assistant is not owned by the user" do
    Current.user = users(:keith)
    conversation = users(:keith).conversations.first
    assistant_owned_by_someone_else = users(:rob).assistants.first

    assert_raises ActiveRecord::RecordInvalid do
      conversation.messages.create!(
        assistant: assistant_owned_by_someone_else,
        content_text: "This should fail"
      )
    end
  end

  test "creating a message with a different assistant and Current.user succeeds when assistant is owned by the user" do
    Current.user = users(:keith)
    conversation = users(:keith).conversations.first
    new_assistant = users(:keith).assistants.where.not(id: conversation.assistant_id).first

    assert_nothing_raised do
      message = conversation.messages.create!(
        assistant: new_assistant,
        content_text: "This works since Assistant is also owned by Current.user"
      )
      assert_equal Current.user, message.assistant.user
    end
  end

  test "creating a message with assistant that does not match the conversation user succeeds when Current.user is not set" do
    conversation = users(:keith).conversations.first
    assistant_owned_by_someone_else = users(:rob).assistants.first
    Current.user = nil

    assert_not_equal conversation.user, assistant_owned_by_someone_else.user

    assert_nothing_raised do
      message = conversation.messages.create!(
        assistant: assistant_owned_by_someone_else,
        content_text: "This works since Current.user not set"
      )
      assert_not_equal conversation.user, message.assistant.user
    end
  end

  test "when a conversation gets a message from a new assistant this propogates to the conversation" do
    old_assistant = conversations(:greeting).assistant
    new_assistant = assistants(:keith_claude3)

    conversations(:greeting).messages.create!(assistant: new_assistant, content_text: "Hello")
    assert_equal new_assistant, conversations(:greeting).reload.assistant
  end

  test "messages are destroyed when a conversation is destroyed" do
    msg1 = messages(:popstate)
    msg2 = messages(:popstate_event)

    assert_difference "Message.count", -2 do
      msg1.conversation.destroy
    end

    assert_equal 0, Message.where(id: [msg1.id, msg2.id]).count
  end

  test "message which is referenced by conversation can be destroyed" do
    assert_equal messages(:popstate_event), conversations(:javascript).last_assistant_message
    messages(:popstate_event).destroy
    assert_nil conversations(:javascript).reload.last_assistant_message
  end

  test "message which is referenced by user can be destroyed" do
    assert_equal messages(:dont_know_day), users(:keith).last_cancelled_message
    messages(:dont_know_day).destroy
    assert_nil users(:keith).reload.last_cancelled_message
  end

  test "a destroyed message nullifies associated memories" do
    memory = messages(:hear_me).memories.first
    messages(:hear_me).destroy

    assert_nil memory.reload.message
  end

  test "modifying input_token_count updates input_token_cost" do
    message = messages(:hear_me)
    message.update!(input_token_count: 5, output_token_cost: 1)
    assert_equal 5 * message.assistant.language_model.input_token_cost_cents, message.input_token_cost
    # make sure output_token_cost is not changed
    assert_equal 1, message.output_token_cost
  end

  test "modifying output_token_count updates output_token_cost" do
    message = messages(:hear_me)
    message.update!(output_token_count: 5, input_token_cost: 1)
    assert_equal 5 * message.assistant.language_model.output_token_cost_cents, message.output_token_cost
    # make sure input_token_cost is not changed
    assert_equal 1, message.input_token_cost
  end
end
