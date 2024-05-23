require "test_helper"

class Toolbox::OpenMeteoTest < ActiveSupport::TestCase
  setup do
    @locations = [
      { name: "Paris", country: "France", admin1: "Ile-de-France" },
      { name: "Paris", country: "United States", admin1: "Texas" },
      { name: "Paris", country: "United States", admin1: "Tennessee" },
      { name: "Paris", country: "United States", admin1: "Kentucky" },
      { name: "Paris", country: "United States", admin1: "Illinois" },
    ].map(&OpenStruct.method(:new))
  end

  test "filter_by_country filters locations by country with a fuzzy match" do
    filtered_locations = Toolbox::OpenMeteo.send(:filter_by_country, "US", locations: @locations)

    @locations.delete_at(0)
    assert_equal @locations, filtered_locations
  end

  test "pick_by_region selects best with a fuzzy match" do
    location = Toolbox::OpenMeteo.send(:pick_by_region, "TX", locations: @locations)
    assert_equal @locations[1], location
  end

  test "get_current_and_todays_weather hits the API and doesn't fail" do
    result = Toolbox::OpenMeteo.get_current_and_todays_weather(city_s: 'Austin', state_province_or_region_s: 'Texas')
    assert result.values.all? { |value| value.present? }
  end
end
