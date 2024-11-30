require "test_helper"

class Message::DocumentImageTest < ActiveSupport::TestCase
  test "has associated documents" do
    assert_instance_of Document, messages(:examine_this).documents.first
  end

  test "documents are deleted upon destroy" do
    assert_difference "Document.count", -1 do
      messages(:examine_this).destroy
    end
  end

  test "has_document_image?" do
    assert messages(:examine_this).has_document_image?
    refute messages(:examine_this).has_document_image?(:small)
  end

  test "document_image_path" do
    assert messages(:examine_this).document_image_path(:small).is_a?(String)
    assert messages(:examine_this).document_image_path(:small).starts_with?("/rails/active_storage/representations/redirect")
  end

  test "document_image_path with fallback" do
    assert_equal "", messages(:examine_this).document_image_path(:small, fallback: "")
  end
end
