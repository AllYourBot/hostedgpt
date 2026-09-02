require "test_helper"
require_relative "../../db/migrate/20260830120000_add_open_router"

class AddOpenRouterMigrationTest < ActiveSupport::TestCase
  setup do
    @user = users(:taylor)
  end

  test "creates a canonical OpenRouter service for users without one" do
    AddOpenRouter.new.up
    service = @user.api_services.find_by(url: APIService::URL_OPENROUTER)
    assert service
    assert_equal "OpenRouter", service.name
    assert_equal "openai", service.driver
  end

  test "adopts a pre-connected openai-driver service under the canonical name instead of duplicating it" do
    custom = @user.api_services.create!(name: "My Router", url: APIService::URL_OPENROUTER, driver: :openai, token: "router-key")

    AddOpenRouter.new.up

    assert_equal 1, @user.api_services.where(url: APIService::URL_OPENROUTER).count
    assert_equal "OpenRouter", custom.reload.name
    assert_equal "router-key", custom.token
  end

  test "leaves a service with another driver at that URL alone and creates the canonical row beside it" do
    other = @user.api_services.create!(name: "Proxy", url: APIService::URL_OPENROUTER, driver: :anthropic, token: "other-key")

    AddOpenRouter.new.up

    assert_equal "Proxy", other.reload.name
    canonical = @user.api_services.find_by(name: "OpenRouter")
    assert canonical
    assert_equal "openai", canonical.driver
  end
end
