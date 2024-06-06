require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, people(:keith_registered).user
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
    user = User.new password: "password", first_name: "John", last_name: "Doe"
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
    user = User.new password: "password", first_name: "John", last_name: "Doe"
    person = Person.new email: "  EXAMPLE@gmail.com  ", personable: user
    person.save!
    assert_equal "example@gmail.com", person.email
  end

  test "it can create a nested user" do
    person = Person.new email: "example@gmail.com", personable_attributes: { password: "password", first_name: "John", last_name: "Doe" }, personable_type: "User"
    assert person.save
    assert_instance_of User, person.personable
  end

  test "person with invalid email format validation" do
    person = Person.new(email: "invalid_email")
    refute person.valid?
    assert_includes person.errors[:email], "is invalid"
    refute person.save, "Person with invalid email was saved"
  end
end
