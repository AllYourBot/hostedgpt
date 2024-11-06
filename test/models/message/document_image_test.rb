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

  test "document_image_url with data url" do
    url = messages(:examine_this).document_image_url(:small)
    assert url.is_a?(String)
    assert url.starts_with?("data:image/png;base64,")
  end
end
