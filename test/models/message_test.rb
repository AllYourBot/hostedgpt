require "test_helper"

class MessageTest < ActiveSupport::TestCase
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
  #   assert_instance_of Document, messages(:identify_photo).content_document
  # end

  test "has associated documents" do
    assert_instance_of Document, messages(:identify_photo).documents.first
  end

  test "has an associated run" do
    assert_instance_of Run, messages(:yes_i_do).run
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

  test "documents are deleted upon destroy" do
    assert_difference "Document.count", -1 do
      messages(:identify_photo).destroy
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
end
