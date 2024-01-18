require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "has an associated person" do
    assert_instance_of Person, users(:keith).person
  end

  test "should not save user without password" do
    user = User.new
    person = Person.new(email: "example@gmail.com", personable: user)
    assert_raises(ActiveRecord::RecordInvalid) { person.save! }
  end

  test "should save user with password" do
    user = User.new(password: "password", password_confirmation: "password")
    person = Person.new(email: "exmaple@gmail.com", personable: user)
    assert person.save!
  end

  test "passwords must be 6 characters or longer" do
    user = User.new
    bad_short_passwords = ["", "12345"]

    bad_short_passwords.each do |bad_password|
      user.password = bad_password
      user.save
      assert user.errors[:password].present?
    end

    good_password = "123456"
    user.password = good_password
    assert user.save
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
