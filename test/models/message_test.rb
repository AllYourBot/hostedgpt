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

  test "has associated user (delegated)" do
    assert_instance_of User, messages(:yes_i_do).user
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

  test "creating a new message on a conversation updates the redis key for that conversation" do
    conversation = conversations(:greeting)
    previous_id = conversation.latest_message.id
    redis.set("conversation-#{conversation.id}-latest_message-id", previous_id)

    assert_changes "redis.get('conversation-#{conversation.id}-latest_message-id')&.to_i", from: previous_id do
      assert_difference "conversation.messages.count", 2 do
        conversation.messages.create!(
          assistant: conversation.assistant,
          content_text: "A new message"
        )
      end
    end

    assert_equal conversation.latest_message.reload.id, redis.get("conversation-#{conversation.id}-latest_message-id")&.to_i
    redis.set("conversation-#{conversation.id}-latest_message-id", previous_id)
  end

  test "when a conversation gets a message from a new assistant this propogates to the conversation" do
    old_assistant = conversations(:greeting).assistant
    new_assistant = assistants(:keith_claude3)

    conversations(:greeting).messages.create!(assistant: new_assistant, content_text: "Hello")
    assert_equal new_assistant, conversations(:greeting).reload.assistant
  end

  test "when a message is cancelled the redis key gets set" do
    redis.set("message-cancelled-id", nil)

    assert_changes "messages(:im_a_bot).cancelled_at", from: nil do
      assert_changes "redis.get('message-cancelled-id')&.to_i", to: messages(:im_a_bot).id do
        messages(:im_a_bot).cancelled!
      end
    end

    redis.set("message-cancelled-id", nil)
  end

  test "has_document_image?" do
    assert messages(:identify_photo).has_document_image?
    refute messages(:identify_photo).has_document_image?(:small)
  end

  test "document_image_path" do
    assert messages(:identify_photo).document_image_path(:small)
    assert messages(:identify_photo).document_image_path(:small).is_a?(String)
    assert messages(:identify_photo).document_image_path(:small).starts_with?("/rails/active_storage/representations/redirect")
  end

  private

  def redis
    RedisConnection.client
  end
end
