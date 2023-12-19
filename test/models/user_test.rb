require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should not save user without password" do
    user = User.new
    person = Person.new(email: "example@gmail.com", personable: user)
    assert_raises(ActiveRecord::RecordInvalid) { person.save! }
  end

  test "should save user with password" do
    user = User.new(password: "password")
    person = Person.new(email: "exmaple@gmail.com", personable: user)
    assert person.save!
  end
end
