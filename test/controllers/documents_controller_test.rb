require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @document = documents(:cat_photo)
  end

  # test "should get index" do
  #   get documents_url
  #   assert_response :success
  # end

  # test "should get new" do
  #   get new_document_url
  #   assert_response :success
  # end

  # test "should create document" do
  #   assert_difference("Document.count") do
  #     post documents_url, params: {document: {user_id: @document.user_id, assistant_id: @document.assistant_id, message_id: @document.message_id, filename: @document.filename, purpose: @document.purpose, bytes: @document.bytes}}
  #   end

  #   assert_redirected_to document_url(Document.last)
  # end

  # test "should show document" do
  #   get document_url(@document)
  #   assert_response :success
  # end

  # test "should get edit" do
  #   get edit_document_url(@document)
  #   assert_response :success
  # end

  # test "should update document" do
  #   patch document_url(@document), params: {document: {user_id: @document.user_id, assistant_id: @document.assistant_id, message_id: @document.message_id, filename: @document.filename, purpose: @document.purpose, bytes: @document.bytes}}
  #   assert_redirected_to document_url(@document)
  # end

  # test "should destroy document" do
  #   assert_difference("Document.count", -1) do
  #     delete document_url(@document)
  #   end

  #   assert_redirected_to documents_url
  # end
end
