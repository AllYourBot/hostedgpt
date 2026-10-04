require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  setup do
    stub_custom_config_value(:app_url_protocol, "https")
    stub_custom_config_value(:app_url_host, "example.com")
    stub_custom_config_value(:app_url_port, nil)
  end

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

  test "defaults the user to the assistant's user when attached to an assistant" do
    file = Rack::Test::UploadedFile.new(file_fixture("test_document.txt"), "text/plain")
    document = Document.create!(assistant: assistants(:samantha), file: file)

    assert_equal assistants(:samantha).user, document.user
    assert_equal "test_document.txt", document.filename
  end

  test "text_content returns the contents of a plain text file" do
    file = Rack::Test::UploadedFile.new(file_fixture("test_document.txt"), "text/plain")
    document = Document.create!(assistant: assistants(:samantha), file: file)

    assert document.has_text?
    assert_includes document.text_content, "This is a text document"
  end

  test "text_content is nil for an image" do
    file = Rack::Test::UploadedFile.new(file_fixture("cat.png"), "image/png")
    document = Document.create!(assistant: assistants(:samantha), file: file)

    refute document.has_text?
    assert_nil document.text_content
  end

  test "text_content is nil when no file is attached" do
    refute documents(:background).has_text?
    assert_nil documents(:background).text_content
  end

  test "image_url returns data url when app_url is not set" do
    stub_custom_config_value(:app_url, "") do
      url = documents(:cat_photo).image_url(:small)

      assert url.starts_with?("data:image/png;base64,")
      assert url.length > 40000
    end
  end

  test "file_base64 downloads each variant only once per document" do
    document = documents(:cat_photo)
    downloads = 0
    counter = ActiveSupport::Notifications.subscribe("service_download.active_storage") { downloads += 1 }

    2.times { document.file_base64(:small) }
    2.times { document.file_base64(:large) }

    assert_equal 2, downloads, "Each variant should be downloaded once, however often it is encoded"
  ensure
    ActiveSupport::Notifications.unsubscribe(counter)
  end

  test "image_link_url is a redirect path when app_url IS NOT SET" do
    stub_custom_config_value(:app_url, "") do
      assert documents(:cat_photo).image_link_url(:large).starts_with?("/rails/active_storage/representations/redirect/"), "Without an app_url the link should be a redirect path, not a data URL"
    end
  end

  test "image_link_url is the processed url when app_url IS SET and the variant exists" do
    documents(:cat_photo).send(:wait_for_file_variant_to_process!, :large)

    stub_custom_config_value(:app_url, "https://example.com") do
      assert documents(:cat_photo).image_link_url(:large).starts_with?("https://example.com/rails/active_storage/postgresql/"), "A processed variant should link straight to the file"
    end
  end

  test "image_link_url is nil for a document WITHOUT an image" do
    assert_nil documents(:background).image_link_url(:large), "A document without an image has nothing to link"
  end

  test "has_file_variant_processed?" do
    refute documents(:cat_photo).has_file_variant_processed?(:small)
  end

  test "fully_processed_url" do
    stub_custom_config_value(:app_url, "https://example.com") do
      assert documents(:cat_photo).fully_processed_url(:small).starts_with?("http")
      assert documents(:cat_photo).fully_processed_url(:small).include?("rails/active_storage/postgresql")
      assert documents(:cat_photo).fully_processed_url(:small).exclude?("/redirect")
    end
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
