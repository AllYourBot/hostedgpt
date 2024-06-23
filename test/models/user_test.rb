require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "has an associated person" do
    assert_instance_of Person, users(:keith).person
  end

  test "has language models" do
    assert users(:keith).language_models.ordered.pluck(:api_name).include?("camel")
    assert users(:taylor).language_models.ordered.pluck(:api_name).include?("pacos-imagine")
  end

  test "has associated credentials" do
    assert_instance_of PasswordCredential, users(:keith).credentials.type_is('PasswordCredential').first
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
end
