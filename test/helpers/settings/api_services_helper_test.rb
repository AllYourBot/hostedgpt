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
end
