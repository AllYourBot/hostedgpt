require "test_helper"

class User::RegisterableTest < ActiveSupport::TestCase
  test "it creates an assistant and a coversation when valid" do
    person = Person.new(email: "example@gmail.com", personable_attributes: { password: "password", first_name: "John", last_name: "Doe" }, personable_type: "User")
    user = person.user

    assert person.save
    assert_instance_of Assistant, user.assistants.first
  end
end
