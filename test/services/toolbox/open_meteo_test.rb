require "test_helper"

class Toolbox::OpenMeteoTest < ActiveSupport::TestCase
  setup do
    @locations = [
      { name: "Paris", country: "France", admin1: "Ile-de-France" },
      { name: "Paris", country: "United States", admin1: "Texas" },
      { name: "Paris", country: "United States", admin1: "Tennessee" },
      { name: "Paris", country: "United States", admin1: "Kentucky" },
      { name: "Paris", country: "United States", admin1: "Illinois" },
    ].map(&OpenData.method(:new))

    @open_meteo = Toolbox::OpenMeteo.new

    @body_forecast = {
      past_days: 1,
      forecast_days: 1,
      current_units: { temperature_2m: "°F", precipitation: "mm" },
      daily: { temperature_2m_max: ["°F"], temperature_2m_min: ["°F"], apparent_temperature_max: ["°F"], apparent_temperature_min: ["°F"], precipitation_sum: ["mm"], precipitation_probability_max: [100], rain_sum: [0], showers_sum: [0], snowfall_sum: [0], weather_code: [1] },
      current: { temperature_2m: ["°F"], precipitation: ["mm"], apparent_temperature: "°F", rain: 1, showers: 1, snowfall: 1, cloud_cover: "yes", weather_code: 1 }
    }
    @body_location = {
      results: [
        {
          admin1: "Texas",
          latitude: 30.2672,
          longitude: -97.7431,
          timezone: "America/Chicago"
        }
      ]
    }
    @body_archive = {
      admin1: "Texas",
      latitude: 30.2672,
      longitude: -97.7431,
      timezone: "America/Chicago",
      daily: { temperature_2m_max: ["°F"], temperature_2m_min: ["°F"], apparent_temperature_max: ["°F"], apparent_temperature_min: ["°F"], precipitation_sum: ["mm"], precipitation_probability_max: [100], rain_sum: [0], showers_sum: [0], snowfall_sum: [0], weather_code: [1] },
    }
  end

  test "filter_by_country filters locations by country with a fuzzy match" do
    filtered_locations = @open_meteo.send(:filter_by_country, "US", locations: @locations)

    @locations.delete_at(0)
    assert_equal @locations, filtered_locations
  end

  test "pick_by_region selects best with a fuzzy match" do
    location = @open_meteo.send(:pick_by_region, "TX", locations: @locations)
    assert_equal @locations[1], location
  end

  test "get_current_and_todays_weather hits the API and doesn't fail" do
    skip("TODO: Fix1 for addition of webmock")

    stub_request(:get, /api.open-meteo.com\/v1\/forecast/)
      .to_return(status: 200, body: @body_forecast.to_json, headers: {})

    stub_request(:get, /geocoding-api.open-meteo.com\/v1\/search/)
      .to_return(status: 200, body: @body_location.to_json, headers: {})

    stub_request(:get, /archive-api.open-meteo.com\/v1\/archive/)
      .to_return(status: 200, body: @body_archive.to_json, headers: {})

    allow_request(:get, :get_location) do
      allow_request(:get, :get_current_and_todays_weather) do
        result = @open_meteo.get_current_and_todays_weather(city_s: "Austin", state_province_or_region_s: "Texas")
        assert result.values.all? { |value| value.present? }
      end
    end
  end

  test "get_current_and_todays_weather works as a tool call" do
    skip("TODO: Fix2 for addition of webmock")

    stub_request(:get, /api.open-meteo.com\/v1\/forecast/)
      .to_return(status: 200, body: @body_forecast.to_json, headers: {})

    stub_request(:get, /geocoding-api.open-meteo.com\/v1\/search/)
      .to_return(status: 200, body: @body_location.to_json, headers: {})

    stub_request(:get, /archive-api.open-meteo.com\/v1\/archive/)
      .to_return(status: 200, body: @body_archive.to_json, headers: {})

    allow_request(:get, :get_location) do
      allow_request(:get, :get_current_and_todays_weather) do
        result = Toolbox.call("openmeteo_get_current_and_todays_weather", city: "Austin", state_province_or_region: "Texas")
        assert result.values.all? { |value| value.present? }
      end
    end
  end
end
