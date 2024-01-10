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
  j
  test "should not save user without password confirmation" do
    user = User.new(password: "password")
    person = Person.new(email: "example@gmail.com", personable: user)
    assert_raises(ActiveRecord::RecordInvalid) { person.save! }
  end

  test "should save user with password" do
    user = User.new(password: "password", password_confirmation: "password")
    person = Person.new(email: "exmaple@gmail.com", personable: user)
    assert person.save!
  end
end
