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

  test "should get new WITH one image starter among the conversation starters" do
    get new_assistant_message_url(@assistant)
    assert_response :success

    image_starter_titles = I18n.t("app.conversations.image_starters").map { |s| s[:title] }
    starter_titles = assigns(:conversation_starters).map(&:first)

    assert_equal 4, starter_titles.size
    assert_equal 1, (starter_titles & image_starter_titles).size
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

  test "index shows no retry button for a message which generated successfully" do
    get conversation_messages_url(@conversation, version: 1)
    assert_select '[data-role="retry"]', false
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

  test "react persists on a message" do
    assert_not @message.user_reacted?("👍", @user)

    post react_message_url(@message), params: { emoji: "👍" }

    assert_response :no_content
    assert @message.reload.user_reacted?("👍", @user)
    assert_equal({ "👍" => 1 }, @message.reaction_counts)
  end

  test "unreact removes a message reaction" do
    @message.react!("👍", @user)

    post unreact_message_url(@message), params: { emoji: "👍" }

    assert_response :no_content
    assert_not @message.reload.user_reacted?("👍", @user)
    assert_equal({}, @message.reaction_counts)
  end

  test "double react on a message is idempotent" do
    post react_message_url(@message), params: { emoji: "👍" }
    assert_response :no_content

    assert_no_difference "Reaction.count" do
      post react_message_url(@message), params: { emoji: "👍" }
    end

    assert_response :no_content
    assert_equal({ "👍" => 1 }, @message.reload.reaction_counts)
  end

  test "unreact on a clear message emoji is a no-op" do
    assert_no_difference "Reaction.count" do
      post unreact_message_url(@message), params: { emoji: "👍" }
    end

    assert_response :no_content
  end

  test "react on a message with a blank emoji is rejected" do
    assert_no_difference "Reaction.count" do
      post react_message_url(@message), params: { emoji: "" }
    end

    assert_response :unprocessable_content
  end

  test "react on another user's message is unauthorized" do
    foreign = messages(:filter_map)
    assert_not_equal @user, foreign.conversation.user

    assert_no_difference "Reaction.count" do
      post react_message_url(foreign), params: { emoji: "👍" }
    end

    assert_response :unauthorized
  end

  test "react on a message requires authentication" do
    get logout_path

    post react_message_url(@message), params: { emoji: "👍" }

    assert_redirected_to login_url
  end

  test "index renders message reaction counts" do
    @message.react!("👍", @user)

    get conversation_messages_url(@conversation, version: @message.version)

    assert_response :success
    assert_match(/data-role="reaction-counts"/, response.body)
    assert_match(/👍/, response.body)
  end

  test "pin persists on a message" do
    assert_not @message.pinned?(@user)

    post pin_message_url(@message)

    assert_response :no_content
    assert @message.reload.pinned?(@user)
    assert_includes Message.pinned_for(@user).map(&:id), @message.id
  end

  test "message pin answers section and button morphs to Turbo requests" do
    post pin_message_url(@message),
      headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

    assert_response :success
    assert_match(/action="replace" target="pinned-messages"/, response.body)
    assert_match(/data-role="pinned-message"/, response.body)
    assert_match(/action="update" target="message_#{@message.id}-pin"/, response.body)
    assert_match(/data-role="unpin-message"/, response.body)
    assert @message.reload.pinned?(@user)
  end

  test "unpin removes a message pin" do
    @message.pin!(@user)
    assert @message.pinned?(@user)

    post unpin_message_url(@message)

    assert_response :no_content
    assert_not @message.reload.pinned?(@user)
    assert_not_includes Message.pinned_for(@user).map(&:id), @message.id
  end

  test "double pin on a message is idempotent" do
    post pin_message_url(@message)
    assert_response :no_content

    assert_no_difference "Pin.count" do
      post pin_message_url(@message)
    end

    assert_response :no_content
    assert @message.reload.pinned?(@user)
  end

  test "unpin on a clear message is a no-op" do
    assert_no_difference "Pin.count" do
      post unpin_message_url(@message)
    end

    assert_response :no_content
    assert_not @message.reload.pinned?(@user)
  end

  test "bookmark persists on a message" do
    assert_not @message.bookmarked?(@user)

    post bookmark_message_url(@message)

    assert_response :no_content
    assert @message.reload.bookmarked?(@user)
    assert_includes Message.bookmarked_for(@user).map(&:id), @message.id
  end

  test "message bookmark answers a button morph to Turbo requests" do
    post bookmark_message_url(@message),
      headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

    assert_response :success
    assert_match(/action="update" target="message_#{@message.id}-bookmark"/, response.body)
    assert_match(/data-role="unbookmark-message"/, response.body)
    assert @message.reload.bookmarked?(@user)
  end

  test "unbookmark removes a message bookmark" do
    @message.bookmark!(@user)
    assert @message.bookmarked?(@user)

    post unbookmark_message_url(@message)

    assert_response :no_content
    assert_not @message.reload.bookmarked?(@user)
    assert_not_includes Message.bookmarked_for(@user).map(&:id), @message.id
  end

  test "double bookmark on a message is idempotent" do
    post bookmark_message_url(@message)
    assert_response :no_content

    assert_no_difference "Bookmark.count" do
      post bookmark_message_url(@message)
    end

    assert_response :no_content
    assert @message.reload.bookmarked?(@user)
  end

  test "unbookmark on a clear message is a no-op" do
    assert_no_difference "Bookmark.count" do
      post unbookmark_message_url(@message)
    end

    assert_response :no_content
    assert_not @message.reload.bookmarked?(@user)
  end

  test "pin on another user's message is unauthorized" do
    foreign = messages(:filter_map)
    assert_not_equal @user, foreign.conversation.user

    assert_no_difference "Pin.count" do
      post pin_message_url(foreign)
    end

    assert_response :unauthorized
    assert_not foreign.reload.pinned?(@user)
  end

  test "unpin on another user's message is unauthorized" do
    foreign = messages(:filter_map)
    assert_not_equal @user, foreign.conversation.user

    assert_no_difference "Pin.count" do
      post unpin_message_url(foreign)
    end

    assert_response :unauthorized
  end

  test "bookmark on another user's message is unauthorized" do
    foreign = messages(:filter_map)
    assert_not_equal @user, foreign.conversation.user

    assert_no_difference "Bookmark.count" do
      post bookmark_message_url(foreign)
    end

    assert_response :unauthorized
    assert_not foreign.reload.bookmarked?(@user)
  end

  test "unbookmark on another user's message is unauthorized" do
    foreign = messages(:filter_map)
    assert_not_equal @user, foreign.conversation.user

    assert_no_difference "Bookmark.count" do
      post unbookmark_message_url(foreign)
    end

    assert_response :unauthorized
  end

  test "pin on a message requires authentication" do
    get logout_path

    post pin_message_url(@message)

    assert_redirected_to login_url
  end

  test "unpin on a message requires authentication" do
    get logout_path

    post unpin_message_url(@message)

    assert_redirected_to login_url
  end

  test "bookmark on a message requires authentication" do
    get logout_path

    post bookmark_message_url(@message)

    assert_redirected_to login_url
  end

  test "unbookmark on a message requires authentication" do
    get logout_path

    post unbookmark_message_url(@message)

    assert_redirected_to login_url
  end

  test "pinning a message leaves conversation pin order untouched" do
    positions_before = @user.conversations.order(:id).pluck(:id, :position)
    pinned_before = Conversation.pinned_for(@user).pluck(:id)

    post pin_message_url(@message)

    assert_response :no_content
    assert_equal positions_before, @user.conversations.order(:id).pluck(:id, :position)
    assert_equal pinned_before, Conversation.pinned_for(@user).pluck(:id)
  end

  test "index renders a pin hover action on each message" do
    get conversation_messages_url(@conversation, version: @message.version)

    assert_response :success
    assert_match(/data-role="pin-message"/, response.body)
    assert_match(%r{/messages/#{@message.id}/pin}, response.body)
  end

  test "index renders an unpin hover action on a pinned message" do
    @message.pin!(@user)

    get conversation_messages_url(@conversation, version: @message.version)

    assert_response :success
    assert_match(/data-role="unpin-message"/, response.body)
    assert_match(%r{/messages/#{@message.id}/unpin}, response.body)
  end

  test "index lists pinned messages with jump targets and unpin" do
    @message.pin!(@user)

    get conversation_messages_url(@conversation, version: @message.version)

    assert_response :success
    assert_equal [@message.id], assigns(:pinned_messages).map(&:id)
    # The section lists the pin with a jump-to-message anchor; the row itself carries the id.
    assert_match(/id="pinned-messages"/, response.body)
    assert_match(/href="#message_#{@message.id}"/, response.body)
    assert_match(/id="message_#{@message.id}"/, response.body)
    assert_match(%r{/messages/#{@message.id}/unpin}, response.body)
  end

  test "index lists pinned messages in display order" do
    second = @conversation.messages.create!(
      assistant: @message.assistant, role: "user", content_text: "second pinned"
    )
    second.pin!(@user)
    @message.pin!(@user)

    get conversation_messages_url(@conversation, version: @message.version)

    assert_response :success
    assert_equal [@message.id, second.id].sort_by { |id| Message.find(id).index }, assigns(:pinned_messages).map(&:id)
  end

  test "index hides the pinned-messages section once unpinned" do
    @message.pin!(@user)
    @message.unpin!(@user)

    get conversation_messages_url(@conversation, version: @message.version)

    assert_response :success
    assert_empty assigns(:pinned_messages)
    assert_match(/id="pinned-messages"/, response.body)
    assert_no_match(/data-role="pinned-message"/, response.body)
  end

  test "index never leaks another user's message pins" do
    foreign = messages(:filter_map)
    foreign.pin!(foreign.conversation.user)

    get conversation_messages_url(@conversation, version: @message.version)

    assert_response :success
    assert_empty assigns(:pinned_messages)
    assert_no_match(/data-role="pinned-message"/, response.body)
  end
end
