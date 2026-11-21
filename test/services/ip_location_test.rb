require "test_helper"

class IPLocationTest < ActiveSupport::TestCase
  test "name_for joins the city, region, and country" do
    stub_get_response(:get_location, status: 200, response: { city: "Austin", region: "Texas", country: "US" }) do
      assert_equal "Austin, Texas, US", IPLocation.name_for("1.2.3.4"), "The place name should list city, region, country"
    end
  end

  test "name_for is nil for a private address" do
    stub_get_response(:get_location, status: 200, response: { ip: "127.0.0.1", bogon: true }) do
      assert_nil IPLocation.name_for("127.0.0.1"), "A private address has no location"
    end
  end

  test "name_for is nil when the lookup fails" do
    stub_get_response(:get_location, status: 429, response: { error: "rate limited" }) do
      assert_nil IPLocation.name_for("1.2.3.4"), "A failed lookup should not raise"
    end
  end

  test "name_for is nil for a blank address without a lookup" do
    assert_nil IPLocation.name_for(nil), "A blank address has no location"
  end
end
