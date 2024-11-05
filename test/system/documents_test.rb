require "application_system_test_case"

class DocumentsTest < ApplicationSystemTestCase
  setup do
    @document = documents(:cat_photo)
  end

  # test "visiting the index" do
  #   visit documents_url
  #   assert_selector "h1", text: "Documents"
  # end

  test "should create document" do
    assert true
    # TODO: We will eventually want to have a general endpoint for updating Documents but we haven't implemented yet so disabling this test.
    #
    # visit documents_url
    # click_text "New document"

    # fill_in "Assistant", with: @document.assistant_id
    # fill_in "Bytes", with: @document.bytes
    # fill_in "Filename", with: @document.filename
    # fill_in "Message", with: @document.message_id
    # fill_in "Purpose", with: @document.purpose
    # fill_in "User", with: @document.user_id
    # click_text "Create Document"

    # assert_text "Document was successfully created"
    # click_text "Back"
  end

  test "should update Document" do
    assert true
    # TODO: We will eventually want to have a general endpoint for updating Documents but we haven't implemented yet so disabling this test.
    #
    # visit document_url(@document)
    # click_text "Edit this document", match: :first

    # fill_in "Assistant", with: @document.assistant_id
    # fill_in "Bytes", with: @document.bytes
    # fill_in "Filename", with: @document.filename
    # fill_in "Message", with: @document.message_id
    # fill_in "Purpose", with: @document.purpose
    # fill_in "User", with: @document.user_id
    # click_text "Update Document"

    # assert_text "Document was successfully updated"
    # click_text "Back"
  end

  # test "should destroy Document" do
  #   visit document_url(@document)
  #   click_text "Destroy this document", match: :first

  #   assert_text "Document was successfully destroyed"
  # end
end
