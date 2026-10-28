require "test_helper"

class Settings::APIServicesHelperTest < ActionView::TestCase

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

  test "cheaper inference is official" do
    assert official?(api_services(:keith_cheaper_inference_service))
  end

  test "cheaper_inference? is true for Cheaper Inference URL" do
    assert cheaper_inference?(api_services(:keith_cheaper_inference_service))
  end

  test "cheaper_inference? is false for other URLs" do
    refute cheaper_inference?(api_services(:keith_openai_service))
    refute cheaper_inference?(api_services(:keith_openrouter_service))
  end

  test "instruction_step renders a translated step whose link opens in a new tab" do
    html = instruction_step("openai.step1_html", "Platform", "https://platform.openai.com/")
    assert html.start_with?("<li>"), "the step should be a list item"
    assert_includes html, '<a class="underline text-blue-600" target="_blank" href="https://platform.openai.com/">Platform</a>', "the link should be interpolated unescaped"
  end
end
