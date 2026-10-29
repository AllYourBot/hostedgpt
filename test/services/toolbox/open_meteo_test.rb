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

  test "get_current_and_todays_weather summarizes the location's forecast" do
    stub_weather_api do
      result = @open_meteo.get_current_and_todays_weather(city_s: "Austin", state_province_or_region_s: "Texas")

      assert result.values.all? { |value| value.present? }
      assert_equal "Austin, Texas, United States", result[:in]
      assert_equal "72 degrees fahrenheit", result[:right_now]
      assert_equal "+3.0 degrees fahrenheit", result[:today_high_change_from_yesterday]
      assert_equal "Currently in Austin there are scattered clouds and it's 72 degrees. Today there's a forecasted low of 61 degrees and a high of 84 degrees.", result[:good_summary]
    end
  end

  test "get_current_and_todays_weather works as a tool call" do
    stub_weather_api do
      result = Toolbox.call("openmeteo_get_current_and_todays_weather", city: "Austin", state_province_or_region: "Texas")

      assert result.values.all? { |value| value.present? }
      assert_equal "Austin, Texas, United States", result[:in]
    end
  end

  test "get_historical_weather reports the day's minimum as the low" do
    stub_get_response(:get_location, status: 200, response: locations_data) do
      stub_get_response(:get_historical_weather, status: 200, response: historical_data) do
        result = @open_meteo.get_historical_weather(
          city_s: "Austin",
          state_province_or_region_s: "Texas",
          date_span_begin_s: "2020-01-01",
          date_span_end_s: "2020-01-02",
        )

        assert_equal [ 50.0, 52.0 ], result.map { |day| day[:temp_high] }
        assert_equal [ 31.0, 33.0 ], result.map { |day| day[:temp_low] }
        assert_equal [ "31 degrees fahrenheit", "33 degrees fahrenheit" ], result.map { |day| day[:temp_low_formatted] }
      end
    end
  end

  private

  def stub_weather_api(&block)
    stub_get_response(:get_location, status: 200, response: locations_data) do
      stub_get_response(:get_current_and_todays_weather, status: 200, response: forecast_data, &block)
    end
  end

  def locations_data
    {
      results: [
        { name: "Austin", latitude: 43.66, longitude: -92.97, timezone: "America/Chicago", country: "United States", admin1: "Minnesota" },
        { name: "Austin", latitude: 30.27, longitude: -97.74, timezone: "America/Chicago", country: "United States", admin1: "Texas" },
      ]
    }
  end

  def historical_data
    {
      daily_units: { temperature_2m_max: "°F", precipitation_sum: "inch" },
      daily: {
        time: [ "2020-01-01", "2020-01-02" ],
        weather_code: [ 3, 2 ],
        temperature_2m_max: [ 50.0, 52.0 ],
        temperature_2m_min: [ 31.0, 33.0 ],
        apparent_temperature_max: [ 49.0, 51.0 ],
        apparent_temperature_min: [ 28.0, 30.0 ],
        precipitation_sum: [ 0.1, 0.0 ],
        rain_sum: [ 0.1, 0.0 ],
        snowfall_sum: [ 0.0, 0.0 ],
      }
    }
  end

  def forecast_data
    {
      current_units: { temperature_2m: "°F", precipitation: "inch" },
      current: {
        temperature_2m: 72.4,
        apparent_temperature: 73.1,
        precipitation: 0.0,
        rain: 0.0,
        showers: 0.0,
        snowfall: 0.0,
        cloud_cover: 40,
        weather_code: 2,
      },
      daily: {
        weather_code: [ 3, 2 ],
        temperature_2m_max: [ 81.0, 84.0 ],
        temperature_2m_min: [ 60.0, 61.0 ],
        apparent_temperature_max: [ 82.0, 85.0 ],
        apparent_temperature_min: [ 59.0, 60.0 ],
        precipitation_sum: [ 0.1, 0.0 ],
        rain_sum: [ 0.1, 0.0 ],
        showers_sum: [ 0.0, 0.0 ],
        snowfall_sum: [ 0.0, 0.0 ],
        precipitation_probability_max: [ 20, 10 ],
      }
    }
  end
end
