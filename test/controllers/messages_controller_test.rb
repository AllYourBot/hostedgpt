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

  test "new should mark the assistants that HAVE context files in the nav column" do
    get new_assistant_message_url(@assistant)
    assert_response :success

    assert_select "#assistant_#{assistants(:samantha).id} [data-role='context-files'][title=?]", I18n.t("app.assistants.ui.context_files"), { count: 1 },
      "The assistant with an uploaded context file should show the context files icon"
    assert_select "#assistants [data-role='context-files']", { count: 1 }, "Assistants without context files should not show the icon"
  end

  test "new should NOT mark an assistant whose only documents are the images it generated" do
    documents(:background).destroy!
    GeneratedImage.new(Base64.strict_encode64(file_fixture("cat.png").binread)).attach_to!(messages(:image_generation_explained))
    assert_equal assistants(:samantha), messages(:image_generation_explained).documents.last.assistant, "The generated image should record the assistant that made it"

    get new_assistant_message_url(@assistant)
    assert_response :success

    assert_select "#assistants [data-role='context-files']", { count: 0 }, "A generated image is not a context file, so no assistant should show the icon"
  end

  test "should show message" do
    get message_url(@message)
    assert_response :success
  end

  test "should get new WITH one image starter among the conversation starters" do
    get new_assistant_message_url(@assistant)
    assert_response :success

    image_starter_titles = I18n.t("app.conversations.image_starters").map { |s| s[:title] }
    starter_titles = assigns(:conversation_starters).map(&:first)

    assert_equal 4, starter_titles.size
    assert_equal 1, (starter_titles & image_starter_titles).size
  end

  test "should get new WITH the assistant's own conversation starters in place of the default ones" do
    questions = ["What should I cook tonight?", "Plan my week"]
    @assistant.update!(conversation_starters: questions)

    get new_assistant_message_url(@assistant)
    assert_response :success

    assert_equal questions, assigns(:conversation_starters).map(&:first), "The assistant's starters should be shown in the order they were saved"
    questions.each do |question|
      assert_select "form[action=?] input[name=?][value=?]", assistant_messages_path(@assistant), "message[content_text]", question,
        { count: 1 }, "Clicking a starter should send its question as written"
    end
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

  test "should create message marked as spoken when it came from voice" do
    post assistant_messages_url(@assistant), params: { message: { conversation_id: @message.conversation_id, content_text: "Hello", spoken: true } }

    assert @conversation.messages.user.order(:created_at).last.spoken?
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

  test "should create message with multiple image attachments" do
    cat_file = fixture_file_upload("cat.png", "image/png")
    dog_file = fixture_file_upload("cat.png", "image/png")

    assert_difference "Conversation.count", 1 do
      assert_difference "Document.count", 2 do
        assert_difference "Message.count", 2 do
          post assistant_messages_url(@assistant), params: { message: {
            documents_attributes: { "0": { file: cat_file }, "1": { file: dog_file } },
            content_text: @message.content_text
          } }
        end
      end
    end

    (user_msg, _asst_msg) = Message.last(2)
    assert_equal 2, user_msg.documents.count
    assert_equal Document.last(2).to_set, user_msg.documents.to_set
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

  test "index shows a retry button for a message which failed to generate" do
    latest_message = @conversation.latest_message_for_version(:latest)
    latest_message.update! content_text: "(I received a blank response.)", failed_at: Time.current

    get conversation_messages_url(@conversation, version: latest_message.version)
    assert_select '[data-role="retry"]:not(.hidden)'
    assert_select '[data-role="retry-button"]'
  end

  test "index hides the retry button behind the watchdog while a message is still generating" do
    @conversation.messages.create! role: :user, content_text: "You there?", assistant: @assistant

    get conversation_messages_url(@conversation, version: 1)
    assert_select '[data-role="retry"].hidden'
    assert_select '[data-controller~="stream-watchdog"]'
  end

  test "index shows an assistant's thinking collapsed once the reply is done" do
    latest_message = @conversation.latest_message_for_version(:latest)
    latest_message.update! thinking_text: "Let me work through this...", thinking_signature: "sig-abc"

    get conversation_messages_url(@conversation, version: latest_message.version)
    assert_select "details[data-role='thinking-text']:not([open])", text: /Let me work through this\.\.\./
  end

  test "index hides an assistant's thinking when the user turned it off" do
    latest_message = @conversation.latest_message_for_version(:latest)
    latest_message.update! thinking_text: "Let me work through this...", thinking_signature: "sig-abc"
    @conversation.user.update!(show_thinking: false)

    get conversation_messages_url(@conversation, version: latest_message.version)
    assert_select "details[data-role='thinking-text']", false
  end

  test "index shows no thinking block for a message without thinking" do
    get conversation_messages_url(@conversation, version: 1)
    assert_select "details[data-role='thinking-text']", false
  end

  test "index shows no retry button for a message which generated successfully" do
    get conversation_messages_url(@conversation, version: 1)
    assert_select '[data-role="retry"]', false
  end

  test "index shows a continue button for the latest reply when it WAS CUT OFF at the token limit" do
    latest_message = @conversation.latest_message_for_version(:latest)
    latest_message.update! truncated_at: Time.current

    get conversation_messages_url(@conversation, version: latest_message.version)
    assert_select '[data-role="continue"]', 1, "The cut-off reply should offer Continue"
    assert_select '[data-role="continue-button"]', 1, "The Continue button should be rendered"
    assert_select '[data-role="retry"]', false, "A cut-off reply did not fail, so it should not offer Retry"
  end

  test "index shows no continue button for a cut-off reply which IS NO LONGER the latest message" do
    latest_message = @conversation.latest_message_for_version(:latest)
    latest_message.update! truncated_at: Time.current
    @conversation.messages.create! role: :user, content_text: "Never mind", assistant: @assistant

    get conversation_messages_url(@conversation, version: latest_message.version)
    assert_select '[data-role="continue"]', false, "Continue only makes sense on the conversation's latest reply"
  end

  test "index shows no continue button for a reply which finished on its own" do
    get conversation_messages_url(@conversation, version: 1)
    assert_select '[data-role="continue"]', false, "A complete reply should not offer Continue"
  end

  test "without an app_url, index embeds only the thumbnails and leaves each modal image to load when opened" do
    conversation = conversations(:attachments)
    images = conversation.messages.flat_map(&:documents).select(&:has_image?)
    images.each { |document| document.send(:wait_for_file_variant_to_process!, :small) }

    downloads = 0
    counter = ActiveSupport::Notifications.subscribe("service_download.active_storage") { downloads += 1 }

    stub_custom_config_value(:app_url, nil) do
      get conversation_messages_url(conversation, version: 1)
    end

    assert_response :success
    assert_equal images.size, downloads, "Only each image's thumbnail should be downloaded"
    assert_select "[data-image-modal][data-image-loader-lazy-value='true']", { count: images.size }, "Every modal image should wait to be opened"
    assert_select "[data-image-modal][data-image-loader-url-value^='/rails/active_storage/representations/redirect/']", { count: images.size }, "Every modal image should be a link, not a data URL"
    assert_select "[data-image-modal] img[src='']", { count: images.size }, "No modal image should start loading on render"
  ensure
    ActiveSupport::Notifications.unsubscribe(counter)
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

  test "when assistant supports images the attachment picker offers images and PDFs" do
    get conversation_messages_url(@conversation, version: 1)
    assert_select "#attach-button"
    assert_select "input#attachment_picker[accept=?]", "image/*,.pdf"
  end

  test "when assistant doesn't support images the attachment picker still offers PDFs" do
    get conversation_messages_url(conversations(:trees), version: 1)
    assert_select "#attach-button"
    assert_select "input#attachment_picker[accept=?]", ".pdf"
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
    @user.assistants.ordered.each do |assistant|
      assert_select %{div[data-radio-behavior-id-param="#{assistant.id}"] a[data-role="name"]}
    end
    @user.assistants.ordered.each_with_index do |assistant, index|
      # The selected assistant is always shown, regardless of its position in the list
      if index < Assistant::MAX_LIST_DISPLAY || assistant == @assistant
        assert_select %{div[data-role="assistant"][data-radio-behavior-id-param="#{assistant.id}"] a[data-role="name"]}
        assert_select %{div.hiden[data-role="assistant"][data-radio-behavior-id-param="#{assistant.id}"] a[data-role="name"]}, false
      else
        assert_select %{div.hidden[data-role="assistant"][data-radio-behavior-id-param="#{assistant.id}"] a[data-role="name"]}
      end
    end
  end
end
