require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "has an associated person" do
    assert_instance_of Person, users(:keith).person
  end

  test "should not validate a new user without password" do
    user = User.new
    person = Person.new(email: "example@gmail.com", personable: user)
    refute person.valid?
  end

  test "should validate a user with minimum information" do
    user = User.new(password: "password", password_confirmation: "password", first_name: "John", last_name: "Doe")
    person = Person.new(email: "exmaple@gmail.com", personable: user)
    assert person.valid?
  end

  test "although first & last name is required for create it's not required for update" do
    assert_nothing_raised do
      users(:keith).update!(first_name: nil, last_name: nil)
    end
  end

  test "it can update a user with a password" do
    user = users(:keith)
    old_password_hash = user.password_digest
    user.update(password: "password")
    assert user.valid?
    refute_equal old_password_hash, user.password_digest
  end

  test "it can update a user without a password" do
    user = users(:keith)
    old_password_hash = user.password_digest
    user.update(first_name: "New Name")
    assert user.valid?
    assert_equal old_password_hash, user.password_digest
  end

  test "passwords must be 6 characters or longer" do
    user = User.new(first_name: "John", last_name: "Doe")
    bad_short_passwords = ["", "12345"]

    bad_short_passwords.each do |bad_password|
      user.password = bad_password
      user.valid?
      assert user.errors[:password].present?
    end

    good_password = "123456"
    user.password = good_password
    assert user.valid?
    refute user.errors[:password].present?
  end

  test "it can validate a password" do
    user = users(:keith)
    assert user.authenticate("secret")
  end

  test "it destroys assistantes on destroy" do
    assistant = assistants(:samantha)
    assistant.user.destroy
    assert_raises ActiveRecord::RecordNotFound do
      assistant.reload
    end
  end

  test "it destroys conversations on destroy" do
    conversation = conversations(:greeting)
    conversation.user.destroy
    assert_raises ActiveRecord::RecordNotFound do
      conversation.reload
    end
  end
end
