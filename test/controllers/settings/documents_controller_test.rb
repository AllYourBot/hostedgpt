require "test_helper"

class Settings::DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @assistant = assistants(:samantha)
    @user = @assistant.user
    login_as @user
  end

  test "should upload a file and associate it with the assistant" do
    file = fixture_file_upload("test_document.txt", "text/plain")

    assert_difference("@assistant.documents.count") do
      post settings_assistant_documents_url(@assistant), params: { document: { file: file } }
    end

    document = @assistant.documents.order(:created_at).last
    assert_equal "test_document.txt", document.filename
    assert_equal @user, document.user
    assert document.file.attached?
    assert_redirected_to edit_settings_assistant_url(@assistant)
    assert flash[:notice].present?
  end

  test "should show an error when no file is chosen" do
    assert_no_difference("Document.count") do
      post settings_assistant_documents_url(@assistant), params: {}
    end

    assert_redirected_to edit_settings_assistant_url(@assistant)
    assert flash[:alert].present?
  end

  test "should not upload to another user's assistant" do
    other_assistant = assistants(:rob_gpt4)
    assert_not_equal @user, other_assistant.user

    assert_no_difference("Document.count") do
      post settings_assistant_documents_url(other_assistant), params: { document: { file: fixture_file_upload("test_document.txt", "text/plain") } }
    end

    assert_response :not_found
  end

  test "should remove a document from the assistant" do
    document = documents(:background)
    assert_equal @assistant, document.assistant

    assert_difference("@assistant.documents.count", -1) do
      delete settings_assistant_document_url(@assistant, document)
    end

    assert_redirected_to edit_settings_assistant_url(@assistant)
    assert flash[:notice].present?
  end

  test "should not remove a document belonging to a different assistant" do
    document = documents(:cat_photo)
    assert_not_equal @assistant, document.assistant

    assert_no_difference("Document.count") do
      delete settings_assistant_document_url(@assistant, document)
    end

    assert_response :not_found
  end

  test "should NOT remove an image the assistant generated in a conversation" do
    message = messages(:image_generation_explained)
    GeneratedImage.new(Base64.strict_encode64(file_fixture("cat.png").binread)).attach_to!(message)
    document = message.documents.last
    assert_equal @assistant, document.assistant, "The generated image should record the assistant that made it"

    assert_no_difference("Document.count") do
      delete settings_assistant_document_url(@assistant, document)
    end

    assert_response :not_found, "Only context files can be removed from the assistant's settings"
  end
end
