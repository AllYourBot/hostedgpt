require "test_helper"

class MessageTest < ActiveSupport::TestCase
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

  test "simple create works" do
    assert_nothing_raised do
      Message.create!(
        conversation: conversations(:greeting),
        role: "user"
      )
    end
  end

  test "creating an assistant message requires a run to be associated" do
    m = Message.new(
      conversation: conversations(:greeting),
      role: "assistant"
    )

    refute m.valid?
    assert m.errors.map(&:attribute).include? :run

    m.run = runs(:identify_photo_response)
    assert m.valid?

    assert_nothing_raised do
      m.save!
    end
  end

  test "documents are deleted upon destroy" do
    assert_difference "Document.count", -1 do
      messages(:identify_photo).destroy
    end
  end
end
