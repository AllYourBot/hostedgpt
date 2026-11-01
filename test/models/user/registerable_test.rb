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
    assert user.language_models.exists?(api_name: "qwen3:8b", api_service: service)
    assert user.assistants.exists?(slug: "qwen3-8b")
  end
end
