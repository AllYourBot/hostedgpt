require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "has an associated person" do
    assert_instance_of Person, users(:keith).person
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

  test "has a last_cancelled_message but can be nil" do
    assert_equal messages(:dont_know_day), users(:keith).last_cancelled_message
    assert_nil users(:rob).last_cancelled_message
  end

  test "assistants scope filters out deleted vs assistants_including_deleted" do
    assert_difference "users(:keith).assistants.length", -1 do
      assert_no_difference "users(:keith).assistants_including_deleted.length" do
        users(:keith).assistants.first.soft_delete
        users(:keith).reload
      end
    end
  end

  test "associations are deleted upon destroy" do
    assert_difference "Assistant.count", -users(:keith).assistants_including_deleted.count do
      assert_difference "Conversation.count", -users(:keith).conversations.count do
        assert_difference "Credential.count", -users(:keith).credentials.count do
          users(:keith).destroy
        end
      end
    end
  end

  test "encrypts openai_key" do
    user = users(:keith)
    old_openai_key = user.openai_key
    old_cipher_text = user.ciphertext_for(:openai_key)
    user.update!(openai_key: "new one")
    assert user.reload
    refute_equal old_cipher_text, user.ciphertext_for(:openai_key)
    assert_equal "new one", user.openai_key
  end

  test "encrypts anthropic_key" do
    user = users(:keith)
    old_anthropic_key = user.anthropic_key
    old_cipher_text = user.ciphertext_for(:anthropic_key)
    user.update!(anthropic_key: "new one")
    assert user.reload
    refute_equal old_cipher_text, user.ciphertext_for(:anthropic_key)
    assert_equal "new one", user.anthropic_key
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
