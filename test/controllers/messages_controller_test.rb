require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @message = messages(:hear_me)
    @conversation = @message.conversation
    @user = @conversation.user
    @assistant = @conversation.assistant
    login_as @user
  end

  test "index REDIRECTS if no version is provided" do
    get conversation_messages_url(@conversation)
    assert_redirected_to conversation_messages_url(@conversation, version: 1)
    follow_redirect!
    assert_response :success
  end

  test "index DOES NOT REDIRECT if version is provided" do
    get conversation_messages_url(@conversation, version: 1)
    assert_response :success
  end

  test "should get new" do
    get new_assistant_message_url(@assistant)
    assert_response :success
  end

  test "should show message" do
    get message_url(@message)
    assert_response :success
  end

  test "should NOT show message when not owned by the logged in user" do
    message_not_owned_by_user = messages(:filter_map)
    assert_not_equal @user, message_not_owned_by_user.conversation.user

    get message_url(message_not_owned_by_user)
    assert_response :unauthorized
  end

  test "should get edit" do
    get edit_assistant_message_url(@assistant, @message)
    assert_response :success
  end

  test "should create message when conversation_id is provided" do
    assert_difference "Message.count", 2 do
      post assistant_messages_url(@assistant), params: { message: { conversation_id: @message.conversation_id, content_text: @message.content_text } }
    end

    assert_redirected_to conversation_messages_url(@conversation, version: 1)
    assert_equal @conversation.id, Message.last.conversation_id
  end

  test "should create message AND create conversation when conversation_id is nil" do
    assert_difference "Message.count", 2 do
      assert_difference "Conversation.count", 1 do
        post assistant_messages_url(@assistant), params: { message: { content_text: @message.content_text } }
      end
    end

    conversation = Message.last.conversation
    assert_instance_of Conversation, conversation
    assert_redirected_to conversation_messages_url(conversation, version: 1)
    assert_equal @assistant, conversation.assistant
    assert_equal @user, conversation.user
  end

  test "after creating message with index and version it saves those details and redirects to the version of the message" do
    assert_difference "Message.count", 2 do
      post assistant_messages_url(@assistant), params: { message: {
        conversation_id: @message.conversation_id,
        content_text: @message.content_text,
        index: 1,
        version: 2,
        branched: true,
        branched_from_version: 1,
      }}
    end

    message1, message2 = Message.last(2)
    assert_equal 1, message1.index
    assert_equal 2, message1.version
    assert_equal 2, message2.index
    assert_equal 2, message2.version
    assert_redirected_to conversation_messages_url(@conversation, version: 2)
  end

  test "should create message with image attachment" do
    test_file = fixture_file_upload("cat.png", "image/png")
    assert_difference "Conversation.count", 1 do
      assert_difference "Document.count", 1 do
        assert_difference "Message.count", 2 do
          post assistant_messages_url(@assistant), params: { message: { documents_attributes: {"0": {file: test_file}}, content_text: @message.content_text } }
        end
      end
    end

    (user_msg, _asst_msg) = Message.last(2)
    assert_equal Document.last, user_msg.documents.first
  end

  test "should create message with PDF attachment" do
    # Create a simple PDF file for testing
    pdf_content = "%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n>>\nendobj\nxref\n0 4\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \ntrailer\n<<\n/Size 4\n/Root 1 0 R\n>>\nstartxref\n174\n%%EOF"

    # Create a temporary PDF file
    test_file = Tempfile.new(["test", ".pdf"])
    test_file.write(pdf_content)
    test_file.rewind

    # Create a proper test file using the same pattern as the image test
    pdf_file = fixture_file_upload(test_file.path, "application/pdf")

    assert_difference "Conversation.count", 1 do
      assert_difference "Document.count", 1 do
        assert_difference "Message.count", 2 do
          post assistant_messages_url(@assistant), params: { message: { documents_attributes: {"0": {file: pdf_file}}, content_text: @message.content_text } }
        end
      end
    end

    (user_msg, _asst_msg) = Message.last(2)
    assert_equal Document.last, user_msg.documents.first
    assert_equal "application/pdf", user_msg.documents.first.file.content_type
    assert user_msg.has_document_pdf?

    test_file.close
    test_file.unlink
  end

  test "should fail to create message when there is no content_text" do
    post assistant_messages_url(@assistant), params: { message: { content_text: nil } }
    assert_response :unprocessable_content
  end

  test "should fail to create message when there are no params" do
    post assistant_messages_url(@assistant)
    assert_response :bad_request
  end

  test "should fail to create a message when index and version are an invalid combination" do
    post assistant_messages_url(@assistant), params: { message: {
      conversation_id: @message.conversation_id,
      content_text: @message.content_text,
      index: 1,
      version: 10,
    }}
    assert_response :unprocessable_content
  end

  test "update succeeds and redirect to message's EXISTING VERSION" do
    message = messages(:message2_v1)

    patch message_url(message), params: { message: { id: message.id, content_text: "new message" } }
    assert_redirected_to conversation_messages_url(message.conversation, version: 1)
  end

  test "update succeeds and redirect to DIFFERENT VERSION when update has a new version in the URL" do
    message = messages(:message2_v1)

    patch message_url(message, version: 2), params: { message: { id: message.id } }
    assert_redirected_to conversation_messages_url(message.conversation, version: 2)
  end

  test "messages can still be viewed when attached to a soft-deleted assistant" do
    @assistant.deleted!
    get conversation_messages_url(@conversation, version: 1)
    assert @conversation.messages.count > 0
    assert_select 'div[data-role="message"]', count: @conversation.messages.count
  end

  test "when assistant is not deleted the deleted-blurb is hidden but the composer is visible" do
    get conversation_messages_url(@conversation, version: 1)
    assert_response :success
    assert_contains_text "main footer", "Samantha has been deleted and cannot assist any longer."
    assert_select "div#composer"
    assert_select "div#composer.hidden", false
  end

  test "when assistant supports images the image upload function is available" do
    get conversation_messages_url(@conversation, version: 1)
    assert_select "div#composer"
    assert_select "div#composer.relationship", false
  end

  test "when assistant doesn't support images the image upload function is not available" do
    get conversation_messages_url(conversations(:trees), version: 1)
    assert_select "div#composer.relationship"
  end

  test "the composer is hidden when viewing a list of messages attached to an assistant that has been soft-deleted" do
    @assistant.deleted!
    get conversation_messages_url(@conversation, version: 1)
    assert_response :success
    assert_contains_text "main footer", "Samantha has been deleted and cannot assist any longer."
    assert_select "footer div.hidden p.text-center", false
    assert_select "div#composer.hidden"
  end

  test "viewing messages in a conversation which has history but the assistant has been soft deleted, the conversation history can still be viewed" do
    @assistant.deleted!
    message = messages(:message2_v1)

    patch message_url(message, version: 2), params: { message: { id: message.id } }
    assert_redirected_to conversation_messages_url(message.conversation, version: 2)

    get conversation_messages_url(message.conversation, version: 2)
    assert_response :success
    assert_contains_text "main", "Where were you born"
  end

  test "when there are many assistants only a few are shown in the nav bar" do
    5.times do |x|
      @user.assistants.create! name: "New assistant #{x+1}", language_model: LanguageModel.find_by(api_name: "gpt-3.5-turbo")
    end
    get conversation_messages_url(@conversation, version: 1)
    @user.assistants.each do |assistant|
      assert_select %{div[data-radio-behavior-id-param="#{assistant.id}"] a[data-role="name"]}
    end
    @user.assistants.each_with_index do |assistant, index|
      if index>5
        assert_select %{div.hidden[data-role="assistant"][data-radio-behavior-id-param="#{assistant.id}"] a[data-role="name"]}
      else
        assert_select %{div[data-role="assistant"][data-radio-behavior-id-param="#{assistant.id}"] a[data-role="name"]}
        assert_select %{div.hiden[data-role="assistant"][data-radio-behavior-id-param="#{assistant.id}"] a[data-role="name"]}, false
      end
    end
  end
end
