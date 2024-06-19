class Toolbox::OpenWeather < Toolbox
  # Followed this guide: https://openweathermap.org/current

  def self.key
    Setting.openweather_key
  end

  describe :get_current_and_todays_weather, <<~S
    Retrieves the current weather and today's forecast for a given location. The location must be specified with a valid city
    and a valid state_province_or_region. The city and state_province_or_region SHOULD NEVER BE INFERRED; meaning, you should
    ask the user to clarify their city or clarify their state_province_or_region if you have not been instructed with those.
  S

  def self.get_current_and_todays_weather(city_s:, state_province_or_region_s:, country_s: nil)
    location = get("https://api.openweathermap.org/geo/1.0/direct").param({
      q: "#{city_s},#{state_province_or_region_s}",
      country_s: country_s,
      limit: 1,
      appid: key
    }.compact).first

    response = get("https://api.openweathermap.org/data/3.0/onecall").param(
      lat: location.lat,
      lon: location.lon,
      units: :imperial,
      appid: key,
    )

    {
      in: location.name,
      right_now: response.current.weather.first.description,
      right_now_degrees: response.current.temp.round,
      right_now_feels_like_degrees: response.current.feels_like.round,
      today: response.daily.first.summary,
      today_high: response.daily.first.temp.max.round,
      today_low: response.daily.first.temp.min.round,
    }
  end
end
