class OpenWeather < SDK
  # Followed this guide: https://openweathermap.org/api

  def self.key
    Setting.openweather_key
  end

  #describe :get_current_weather, "Get the current weather in a given location"
  def self.get_current_weather(city_s:, state_s:, format_enum_celcius_farenheit:, country_s: "US")
    location = get(
      "http://api.openweathermap.org/geo/1.0/direct?q=#{city_s},#{state_s},#{country_s}&limit=1&appid=#{key}"
    ).first

    response = get("https://api.openweathermap.org/data/3.0/onecall?lat=#{location.lat}&lon=#{location.lon}&units=imperial&appid=#{key}")
    #response = get("https://api.openweathermap.org/data/3.0/onecall/overview?lat=#{location.lat}&lon=#{location.lon}&units=imperial&appid=#{key}")

    {
      in: location.name,
      right_now: response.current.weather.first.description,
      right_now_degrees: response.current.feels_like.round,
      today: response.daily.first.summary,
      today_high: response.daily.first.temp.max.round,
      today_low: response.daily.first.temp.min.round,
    }
  end
end
