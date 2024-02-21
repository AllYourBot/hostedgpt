require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, people(:keith_registered).user
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
end
