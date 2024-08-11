require "test_helper"

class User::RegisterableTest < ActiveSupport::TestCase
  test "it creates an assistant and a coversation when valid" do
    people(:ali_invited).update!(personable_type: "User", personable_attributes: { first_name: "John", last_name: "Doe", })
    assert_instance_of Assistant, people(:ali_invited).user.assistants.first
  end
end
