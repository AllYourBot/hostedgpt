require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, documents(:cat_photo).user
  end

  test "has an associated assistant" do
    assert_instance_of Assistant, documents(:background).assistant
  end

  test "has an associated message" do
    assert_instance_of Message, documents(:cat_photo).message
  end

  test "create fails without a file" do
    assert_raises ActiveRecord::RecordInvalid do
      Document.create!(
        user: users(:keith),
        filename: "dog_photo.jpg",
        purpose: "assistants",
        bytes: 123
      )
    end
  end

  test "simple create works" do
    file_path = File.join(File.dirname(__FILE__), "../assets/cat-image-for-attaching.png")
    file = Rack::Test::UploadedFile.new(file_path, "image/png")

    document = nil
    assert_nothing_raised do
      document = Document.create!(
        user: users(:keith),
        file: file
      )
    end

    assert document.file.attached?
  end

  test "file_data_url returns for a file" do
    prefix = "data:image/png;base64,"
    assert documents(:cat_photo).file_data_url
    assert documents(:cat_photo).file_data_url.starts_with?(prefix)
    assert documents(:cat_photo).file_data_url.length > 40000
  end

  test "file_base64 returns a long string" do
    assert documents(:cat_photo).file_base64.length > 40000
  end

  test "has_file_variant_processed?" do
    refute documents(:cat_photo).has_file_variant_processed?(:small)
  end

  test "fully_processed_url" do
    assert documents(:cat_photo).fully_processed_url(:small).include?('rails/active_storage/postgresql')
    assert documents(:cat_photo).fully_processed_url(:small).exclude?('/redirect')
  end

  test "redirect_to_processed_path" do
    assert documents(:cat_photo).redirect_to_processed_path(:small).starts_with?("/rails")
    assert documents(:cat_photo).redirect_to_processed_path(:small).include?("representations/redirect")
    assert documents(:cat_photo).redirect_to_processed_path(:small).exclude?("rails/active_storage/postgresql")
  end

  test "associations are deleted upon destroy" do
    assert_nothing_raised do
      documents(:cat_photo).destroy!
    end
  end
end
