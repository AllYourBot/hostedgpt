require "test_helper"

class Settings::APIServicesHelperTest < ActiveSupport::TestCase

  include Settings::APIServicesHelper

  test "openai is official" do
    assert official?(api_services(:keith_openai_service))
  end

  test "not all are official" do
    refute official?(api_services(:rob_other_service))
  end

  test "anthropic is official" do
    assert official?(api_services(:rob_anthropic_service))
  end

  test "brave is official" do
    assert official?(api_services(:keith_brave_service))
  end

  test "openrouter is official" do
    assert official?(api_services(:keith_openrouter_service))
  end

  test "openrouter? is true for OpenRouter URL" do
    assert openrouter?(api_services(:keith_openrouter_service))
  end

  test "openrouter? is false for non-OpenRouter URLs" do
    refute openrouter?(api_services(:keith_openai_service))
    refute openrouter?(api_services(:keith_groq_service))
  end
end
