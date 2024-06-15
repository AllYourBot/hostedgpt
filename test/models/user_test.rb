require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "has an associated person" do
    assert_instance_of Person, users(:keith).person
  end

  test "has language models" do
    assert_equal ["camel", "guanaco:large"], users(:keith).language_models.ordered.pluck(:name)
    assert_equal ["alpaca:medium", "pacos-imagine"], users(:taylor).language_models.ordered.pluck(:name)
    assert_equal [], users(:rob).language_models.ordered.pluck(:name)
  end

  test "has usable language models" do
    system = LanguageModel.where(user_id: nil).all.pluck(:name).sort
    assert_equal (system + ["camel", "guanaco:large"]).sort, users(:keith).usable_language_models.pluck(:name).sort
    assert_equal (system + ["alpaca:medium", "pacos-imagine"]).sort, users(:taylor).usable_language_models.pluck(:name).sort
    assert_equal system, users(:rob).usable_language_models.pluck(:name).sort
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

  test "has an associated http_header_credential" do
    assert_instance_of HttpHeaderCredential, users(:rob).http_header_credential
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

  test "when default_llm_keys is enabled but left blank then user keys will be used" do
    user = users(:keith)
    user.update!(openai_key: "GPT321", anthropic_key: "CLAUDE123")

    stub_features(default_llm_keys: true) do
      stub_settings(default_openai_key: " ", default_anthropic_key: "") do
        assert_equal "GPT321", user.preferred_openai_key
        assert_equal "CLAUDE123", user.preferred_anthropic_key
      end
    end
  end

  test "when default_llm_keys is enabled then empty user keys will fall back to default keys" do
    user = users(:keith)
    user.update!(openai_key: " ", anthropic_key: nil)

    stub_features(default_llm_keys: true) do
      stub_settings(default_openai_key: "gpt321", default_anthropic_key: "claude123") do
        assert_equal "gpt321", user.preferred_openai_key
        assert_equal "claude123", user.preferred_anthropic_key
      end
    end
  end
end
