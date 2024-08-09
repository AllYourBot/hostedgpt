require "test_helper"

class User::RegisterableTest < ActiveSupport::TestCase
  test "it creates an assistant and a conversation when valid" do
    people(:ali_invited).update!(personable_type: "User", personable_attributes: { first_name: "John", last_name: "Doe", })
    assert_instance_of Assistant, people(:ali_invited).user.assistants.first
  end

  test "it creates some language models with tools enabled and some without" do
    people(:ali_invited).update!(personable_type: "User", personable_attributes: { first_name: "John", last_name: "Doe", })
    assert people(:ali_invited).user.language_models.where(supports_tools: false).present?
    assert people(:ali_invited).user.language_models.where(supports_tools: true).present?
  end
end
