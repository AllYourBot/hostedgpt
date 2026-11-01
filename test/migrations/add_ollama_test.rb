require "test_helper"
require_relative "../../db/migrate/20261101120000_add_ollama"

class AddOllamaMigrationTest < ActiveSupport::TestCase
  setup do
    @user = users(:taylor)
  end

  test "creates an Ollama service for users without one" do
    AddOllama.new.up
    service = @user.api_services.find_by(url: APIService::URL_OLLAMA)
    assert service
    assert_equal "Ollama", service.name
    assert_equal "openai", service.driver
  end

  test "adopts a pre-connected openai-driver service and keeps its token" do
    custom = @user.api_services.create!(name: "Local", url: APIService::URL_OLLAMA, driver: :openai, token: "my-key")

    AddOllama.new.up

    assert_equal 1, @user.api_services.where(url: APIService::URL_OLLAMA).count
    assert_equal "Ollama", custom.reload.name
    assert_equal "my-key", custom.token
  end

  test "is idempotent" do
    2.times { AddOllama.new.up }
    assert_equal 1, @user.api_services.where(url: APIService::URL_OLLAMA).count
  end
end
