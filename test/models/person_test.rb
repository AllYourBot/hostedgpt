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
end
