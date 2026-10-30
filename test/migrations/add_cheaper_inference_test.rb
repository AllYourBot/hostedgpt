require "test_helper"
require_relative "../../db/migrate/20261028120000_add_cheaper_inference"

class AddCheaperInferenceMigrationTest < ActiveSupport::TestCase
  setup do
    @user = users(:taylor)
  end

  test "creates a canonical Cheaper Inference service for users without one" do
    AddCheaperInference.new.up
    service = @user.api_services.find_by(url: APIService::URL_CHEAPER_INFERENCE)
    assert service
    assert_equal "Cheaper Inference", service.name
    assert_equal "openai", service.driver
  end

  test "adopts a pre-connected openai-driver service under the canonical name instead of duplicating it" do
    custom = @user.api_services.create!(name: "My Gateway", url: APIService::URL_CHEAPER_INFERENCE, driver: :openai, token: "gateway-key")

    AddCheaperInference.new.up

    assert_equal 1, @user.api_services.where(url: APIService::URL_CHEAPER_INFERENCE).count
    assert_equal "Cheaper Inference", custom.reload.name
    assert_equal "gateway-key", custom.token
  end

  test "leaves a service with another driver at that URL alone and creates the canonical row beside it" do
    other = @user.api_services.create!(name: "Proxy", url: APIService::URL_CHEAPER_INFERENCE, driver: :anthropic, token: "other-key")

    AddCheaperInference.new.up

    assert_equal "Proxy", other.reload.name
    canonical = @user.api_services.find_by(name: "Cheaper Inference")
    assert canonical
    assert_equal "openai", canonical.driver
  end
end
