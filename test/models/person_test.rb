require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, people(:keith_registered).user
  end

  test "has associated clients" do
    assert_instance_of Client, people(:keith_registered).clients.first
  end

  test "associations are deleted upon destroy" do
    assert_difference "User.count", -1 do
      assert_difference "Client.count", -people(:keith_registered).clients.count do
        people(:keith_registered).destroy
      end
    end
  end

  test "encrypts email" do
    person = people(:rob_registered)
    old_email = person.email
    old_cipher_text = person.ciphertext_for(:email)
    person.update!(email: "new@address.net")
    assert person.reload
    refute_equal old_cipher_text, person.ciphertext_for(:email)
    assert_equal "new@address.net", person.email
  end

  # Appears length limit for email addresses is 256
  test "encrypts long emails" do
    user = User.new first_name: "John", last_name: "Doe"
    long_email_address = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx@xxx.net"
    assert_equal 256, long_email_address.length
    person = Person.new email: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx@xxx.net", personable: user
    person.save!
    person.reload
    assert_equal long_email_address, person.email
  end

  test "requires email addresses to be unique" do
    person1 = users(:keith).person
    person2 = Person.new(email: person1.email)
    person2.save

    assert person2.errors[:email].present?
  end

  test "it cleans and formats the email address before saving" do
    user = User.new first_name: "John", last_name: "Doe"
    person = Person.new email: "  EXAMPLE@gmail.com  ", personable: user
    person.save!
    assert_equal "example@gmail.com", person.email
  end

  test "person cannot have an invalid email" do
    person = Person.new(email: "invalid_email")
    refute person.valid?
    assert_includes person.errors[:email], "is invalid"
    refute person.save, "Person with invalid email was saved"
  end

  test "it can create a nested user" do
    person = Person.new({
      email: "example@gmail.com",
      personable_type: "User",
      personable_attributes: {
        first_name: "John",
        last_name: "Doe",
        credentials_attributes: {
          '0' => {
            type: "PasswordCredential",
            password: "password",
          }
        }
      }
    })
    assert_difference "User.count", 1 do
      assert_difference "Credential.count", 1 do
        assert person.save
      end
    end
    assert_instance_of User, person.personable
    assert_instance_of PasswordCredential, person.user.credentials.first
  end

  test "the nested user errors without a last name" do
    person = Person.new({
      email: "example@gmail.com",
      personable_type: "User",
      personable_attributes: {
        first_name: "John",
        last_name: nil,
        credentials_attributes: {
          '0' => {
            type: "PasswordCredential",
            password: "password",
          }
        }
      }
    })
    refute person.save
    assert person.user.errors[:last_name].present?
  end

  test "the nested user CAN save without a last name when creating a GoogleCredential" do
    # This test is in person_test rather than user_test because the oauth controller creates it through person
    person = Person.new({
      email: "example@gmail.com",
      personable_type: "User",
      personable_attributes: {
        first_name: "John",
        last_name: nil,
        credentials_attributes: {
          '0' => {
            type: "GoogleCredential",
            oauth_id: "123",
            oauth_token: "abc-123",
            oauth_refresh_token: "def-456",
            oauth_email: "other-rob-email@gmail.com",
            properties: {}
          }
        }
      }
    })
    assert_difference "User.count", 1 do
      assert_difference "Credential.count", 1 do
        assert person.save
      end
    end
    assert_instance_of User, person.personable
    assert_instance_of GoogleCredential, person.user.credentials.first
  end
end
