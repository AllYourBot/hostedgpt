require "test_helper"

class AIBackendTest < ActiveSupport::TestCase
  test "key_error_message returns the name-free fallback copy" do
    assert_equal "(There is a configuration error with this API Service. Maybe you have an invalid API key? " +
      "Click your Profile in the bottom left and then Settings and then **API Services**.)",
      AIBackend.key_error_message
  end

  test "billing_url returns nil for the name-free base default" do
    assert_nil AIBackend.billing_url
  end
end
