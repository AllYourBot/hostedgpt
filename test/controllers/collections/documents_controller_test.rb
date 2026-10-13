require "test_helper"

class Collections::DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @collection = collections(:recipes)
    @user = @collection.user
    login_as @user
  end

  test "should upload a file and associate it with the collection" do
    file = fixture_file_upload("test_document.txt", "text/plain")

    assert_difference("@collection.documents.count") do
      post collection_documents_url(@collection), params: { document: { file: file } }
    end

    document = @collection.documents.order(:created_at).last
    assert_equal "test_document.txt", document.filename, "The filename should come from the upload"
    assert_equal @user, document.user, "The document should belong to the collection's owner"
    assert document.file.attached?, "The uploaded file should be attached"
    assert_redirected_to edit_collection_url(@collection)
    assert flash[:notice].present?, "A success notice should be shown"
  end

  test "should show an error when NO FILE is chosen" do
    assert_no_difference("Document.count") do
      post collection_documents_url(@collection), params: {}
    end

    assert_redirected_to edit_collection_url(@collection)
    assert flash[:alert].present?, "An error alert should be shown"
  end

  test "should not upload to ANOTHER USER'S collection" do
    assert_no_difference("Document.count") do
      post collection_documents_url(collections(:taxes)), params: { document: { file: fixture_file_upload("test_document.txt", "text/plain") } }
    end

    assert_response :not_found
  end

  test "should remove a document from the collection" do
    assert_difference("@collection.documents.count", -1) do
      delete collection_document_url(@collection, documents(:lasagna_recipe))
    end

    assert_redirected_to edit_collection_url(@collection)
  end

  test "should not remove ANOTHER COLLECTION'S document" do
    assert_no_difference("Document.count") do
      delete collection_document_url(@collection, documents(:background))
    end

    assert_response :not_found
  end
end
