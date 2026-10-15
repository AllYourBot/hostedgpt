require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "has an associated person" do
    assert_instance_of Person, users(:keith).person
  end

  test "has associated language_models" do
    assert_instance_of LanguageModel, users(:keith).language_models.first
  end

  test "has associated credentials" do
    assert_instance_of PasswordCredential, users(:keith).credentials.type_is("PasswordCredential").first
  end

  test "has an associated password_credential" do
    assert_instance_of PasswordCredential, users(:keith).password_credential
  end

  test "has an associated google_credential" do
    assert_instance_of GoogleCredential, users(:keith).google_credential
  end

  test "has an associated gmail_credential" do
    assert_instance_of GmailCredential, users(:keith).gmail_credential
  end

  test "has an associated google_tasks_credential" do
    assert_instance_of GoogleTasksCredential, users(:keith).google_tasks_credential
  end

  test "has an associated microsoft_graph_credential" do
    assert_instance_of MicrosoftGraphCredential, users(:keith).microsoft_graph_credential
  end

  test "has an associated http_header_credential" do
    assert_instance_of HttpHeaderCredential, users(:rob).http_header_credential
  end

  test "has associated memories" do
    assert_instance_of Memory, users(:keith).memories.first
  end

  test "has a last_cancelled_message but can be nil" do
    assert_equal messages(:dont_know_day), users(:keith).last_cancelled_message
    assert_nil users(:rob).last_cancelled_message
  end

  test "assistants scope filters out deleted vs assistants_including_deleted" do
    assert_difference "users(:keith).assistants.length", -1 do
      assert_no_difference "users(:keith).assistants_including_deleted.length" do
        users(:keith).assistants.first.deleted!
        users(:keith).reload
      end
    end
  end

  test "associations are deleted upon destroy" do
    assert_difference "APIService.count", -users(:keith).api_services_including_deleted.count do
      assert_difference "LanguageModel.count", -users(:keith).language_models_including_deleted.count do
        assert_difference "Assistant.count", -users(:keith).assistants_including_deleted.count do
          assert_difference "Conversation.count", -users(:keith).conversations.count do
            assert_difference "Credential.count", -users(:keith).credentials.count do
              assert_difference "Memory.count", -users(:keith).memories.count do
                users(:keith).destroy
              end
            end
          end
        end
      end
    end
  end

  test "should validate a user with minimum information" do
    user = User.new(first_name: "John", last_name: "Doe")
    person = Person.new(email: "example@gmail.com", personable: user)
    assert person.valid?
  end

  test "should validate presence of first name" do
    user = users(:keith)
    user.update(first_name: nil)
    refute user.valid?
    assert_equal ["can't be blank"], user.errors[:first_name]
  end

  test "although last name is required for create it's not required for update" do
    assert_nothing_raised do
      users(:keith).update!(last_name: nil)
    end
  end

  # Tests for creating_google_credential? are in person_test

  # Profile picture tests
  test "has_profile_picture? returns false when no profile picture attached" do
    user = users(:keith)
    refute user.has_profile_picture?
  end

  test "has_profile_picture? returns true when profile picture is attached" do
    user = users(:keith)
    user.profile_picture.attach(
      io: StringIO.new("fake image data"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )
    assert user.has_profile_picture?
  end

  test "profile_picture_url returns nil when no profile picture attached" do
    user = users(:keith)
    assert_nil user.profile_picture_url
  end

  test "profile_picture_url returns URL when profile picture is attached" do
    user = users(:keith)
    user.profile_picture.attach(
      io: StringIO.new("fake image data"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )
    assert_not_nil user.profile_picture_url
    assert user.profile_picture_url.include?("test.jpg")
  end

  test "remove_profile_picture= removes attached profile picture" do
    user = users(:keith)
    user.profile_picture.attach(
      io: StringIO.new("fake image data"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )
    assert user.has_profile_picture?

    user.remove_profile_picture = "1"
    refute user.has_profile_picture?
  end

  test "remove_profile_picture= does nothing when no profile picture attached" do
    user = users(:keith)
    refute user.has_profile_picture?

    assert_nothing_raised do
      user.remove_profile_picture = "1"
    end
    refute user.has_profile_picture?
  end

  test "profile picture validates content type" do
    user = users(:keith)
    user.profile_picture.attach(
      io: StringIO.new("fake file data"),
      filename: "test.txt",
      content_type: "text/plain"
    )
    refute user.valid?
    assert_includes user.errors[:profile_picture], "must be a valid image format (JPEG, PNG, GIF, or WebP)"
  end

  test "profile picture validates file size" do
    user = users(:keith)
    # Create a large fake file (6MB)
    large_data = "x" * (6 * 1024 * 1024)
    user.profile_picture.attach(
      io: StringIO.new(large_data),
      filename: "large.jpg",
      content_type: "image/jpeg"
    )
    refute user.valid?
    assert_includes user.errors[:profile_picture], "must be less than 5MB"
  end

  test "profile picture accepts valid image formats" do
    user = users(:keith)
    %w[image/jpeg image/jpg image/png image/gif image/webp].each do |content_type|
      user.profile_picture.attach(
        io: StringIO.new("fake image data"),
        filename: "test.#{content_type.split('/').last}",
        content_type: content_type
      )
      assert user.valid?, "Should accept #{content_type}"
      user.profile_picture.purge
    end
  end
end
