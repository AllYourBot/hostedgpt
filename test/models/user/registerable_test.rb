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

  test "it provisions an OpenRouter service for the new user" do
    people(:ali_invited).update!(personable_type: "User", personable_attributes: { first_name: "John", last_name: "Doe", })
    user = people(:ali_invited).user
    assert user.api_services.exists?(name: "OpenRouter", url: APIService::URL_OPENROUTER, driver: "openai")
  end

  test "it provisions an Ollama service with a sample model and assistant for the new user" do
    people(:ali_invited).update!(personable_type: "User", personable_attributes: { first_name: "John", last_name: "Doe", })
    user = people(:ali_invited).user
    service = user.api_services.find_by(name: "Ollama", url: APIService::URL_OLLAMA, driver: "openai")
    assert service
    assert user.language_models.find_by(api_name: "qwen3:8b", api_service: service).supports_tools?
    assert user.assistants.exists?(slug: "qwen3-8b")
  end

  test "the FIRST user to register becomes an admin" do
    User.stub(:exists?, false) do
      user = User.create!(first_name: "Ali", last_name: "Smith")
      assert user.admin?, "The first user should be an admin"
    end
  end

  test "a user who registers AFTER others exist is not an admin" do
    assert User.exists?, "Fixtures should provide existing users"
    user = User.create!(first_name: "Ali", last_name: "Smith")
    refute user.admin?, "Later users should not be admins"
  end

  test "a later user created AS an admin stays an admin" do
    user = User.create!(first_name: "Ali", last_name: "Smith", admin: true)
    assert user.admin?, "An explicit admin flag should be kept"
  end
end
