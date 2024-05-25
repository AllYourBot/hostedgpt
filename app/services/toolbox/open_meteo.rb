class Toolbox::OpenMeteo < Toolbox
  # Followed this guide: https://open-meteo.com/en/docs

  describe :get_current_and_todays_weather, <<~S
    Retrieves the current weather and today's forecast for a given location. The location must be specified with a valid city
    and a valid state_province_or_region. The city and state_province_or_region SHOULD NEVER BE INFERRED; meaning, you should
    ask the user to clarify their city or clarify their state_province_or_region if you have not been instructed with those.
  S

  def self.get_current_and_todays_weather(city_s:, state_province_or_region_s:, country_s: nil)
    location = get_location(city_s, state_province_or_region_s, country_s)

    response = get("https://api.open-meteo.com/v1/forecast").params(
      past_days: 1,
      forecast_days: 1,

      latitude: location.latitude,
      longitude: location.longitude,
      timezone: location.timezone,

      temperature_unit: "fahrenheit",
      wind_speed_unit: "mph",
      precipitation_unit: "inch",

      current: "weather_code,temperature_2m,apparent_temperature,precipitation,rain,showers,snowfall,cloud_cover",
      #hourly:  "weather_code,temperature_2m,apparent_temperature,precipitation_probability,precipitation,rain,showers,snowfall,snow_depth,cloud_cover",
      daily:   "weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,precipitation_sum,rain_sum,showers_sum,snowfall_sum,precipitation_probability_max",
    )

    degrees = response.current_units.temperature_2m
    quantity = response.current_units.precipitation

    yh = response.daily.temperature_2m_max[0]
    yhf = response.daily.apparent_temperature_max[0]
    yl = response.daily.temperature_2m_min[0]
    ylf = response.daily.apparent_temperature_min[0]

    th = response.daily.temperature_2m_max[1]
    thf = response.daily.apparent_temperature_max[1]
    tl = response.daily.temperature_2m_min[1]
    tlf = response.daily.apparent_temperature_min[1]

    curr = response.current.temperature_2m
    curr_feel = response.current.apparent_temperature

    near_high = (curr - th).abs <= 2
    near_low = (curr - tl).abs <= 2

    if near_high
      phrase = "at today's high of "
      near_low = false
    elsif near_low
      phrase = "at today's low of "
    else
      phrase = ""
    end

    summary = "Currently in #{location.name} it's #{phrase}#{curr.round} degrees with "
    summary += weather_code_to_description(response.current.weather_code) # "scattered showers"

    if response.current.apparent_temperature - curr >= 5
      summary += ", but it feels like #{curr_feel.round} degrees. "
    else
      summary += ". "
    end

    summary += "Today there's a forecasted "
    summary += "low of #{tl.round} degrees" if (!near_low)
    summary += " and a " if (!near_high && !near_low)
    summary += "high of #{th.round} degrees" if (!near_high)

    summary += " with " + weather_code_to_description(response.daily.weather_code[1])

    if thf - th >= 5
      summary += ", but it will feel like #{thf.round} degrees."
    else
      summary += "."
    end

    {
      in: "#{location.name}, #{location.admin1}, #{location.country}",

      right_now: "#{curr.round}#{degrees}",
      right_now_feels_like: "#{curr_feel.round}#{degrees}",

      right_now_precipitation: "#{response.current.precipitation.round} #{quantity}",
      right_now_rain: "#{response.current.rain.round} #{quantity}",
      right_now_showers: "#{response.current.showers.round} #{quantity}",
      right_now_snowfall: "#{response.current.snowfall.round} #{quantity}",
      right_now_cloud_cover: "#{response.current.cloud_cover.round}%",

      today_high: "#{th.round}#{degrees}",
      today_high_feels_like: "#{thf.round}#{degrees}",
      today_low: "#{tl.round}#{degrees}",
      today_low_feels_like: "#{tlf.round}#{degrees}",

      today_high_change_from_yesterday: "#{th > yh ? "+" :''}#{(th - yh).round}#{degrees}",
      today_high_feels_like_change_from_yesterday: "#{thf > yhf ? "+" :''}#{(thf - yhf).round}#{degrees}",
      today_low_change_from_yesterday: "#{tl > yl ? "+" :''}#{(tl - yl).round}#{degrees}",
      today_low_feels_like_change_from_yesterday: "#{tlf > ylf ? "+" :''}#{(tlf - ylf).round}#{degrees}",

      today_now_precipitation: "#{response.daily.precipitation_sum[1]} #{quantity}",
      today_now_precipitation_probability: "#{response.daily.precipitation_probability_max[1]}%",
      today_now_rain: "#{response.daily.rain_sum[1]} #{quantity}",
      today_now_showers: "#{response.daily.showers_sum[1]} #{quantity}",
      today_now_snowfall: "#{response.daily.snowfall_sum[1]} #{quantity}",

      good_summary: summary,
      # right_now_weather_code: response.current.weather_code,
      # today_weather_code: response.daily.weather_code[1],
    }
  end

  class << self
    private

    def get_location(city_s, state_province_or_region_s, country_s = nil)
      locations = get("https://geocoding-api.open-meteo.com/v1/search").params(
        name: city_s,
        count: 5,
        language: "en",
        format: "json",
      ).results

      locations = filter_by_country(country_s, locations: locations) if country_s.present?
      pick_by_region(state_province_or_region_s, locations: locations)
    end

    def filter_by_country(country_s, locations:)
      countries = locations.map(&:country)
      country = countries[ pick_best_index(input: country_s, options: countries) ]

      locations.select { |l| l.country == country }
    end

    def pick_by_region(region_s, locations:)
      best_index = pick_best_index(input: region_s, options: locations.map(&:admin1).map(&:to_s))
      locations[best_index]
    end

    def pick_best_index(input:, options: [])
      input = Amatch::JaroWinkler.new(input)
      options_hash = options.each_with_index.to_h { |value, index| [index, value] }
      options_hash.each do |index, option|
        options_hash[index] = input.match(option)
      end

      highest_match_sort_with_lowest_index_tiebreaker = options_hash.sort do |a,b|
        [b.second, a.first] <=> [a.second, b.first]
      end

      highest_match_sort_with_lowest_index_tiebreaker.first.first # returns the index
    end

    def weather_code_to_description(code)
      # it's 85 degrees with
      case code
      when 0 then "clear skies"
      when 1 then "mostly clear skies"
      when 2 then "scattered clouds" # "and partly cloudy"
      when 3 then "overcast skies"
      when 45 then "fog" # "and foggy"
      when 48 then "freezing fog"
      when 51 then "light drizzle"
      when 53 then "drizzle" #"and drizzling"
      when 55 then "heavy drizzle"
      when 56 then "light freezing drizzle"
      when 57 then "freezing drizzle"
      when 61 then "light rain"
      when 63 then "rain" # "and raining"
      when 65 then "heavy rain" # "and raining heavily"
      when 66 then "light freezing rain"
      when 67 then "freezing rain"
      when 71 then "light snow"
      when 73 then "snow" # "and snowing"
      when 75 then "heavy snow" # "and snowing heavily"
      when 77 then "snow drizzle"
      when 80 then "light scattered showers"
      when 81 then "scattered showers"
      when 82 then "heavy scattered showers"
      when 85 then "light scattered snow"
      when 86 then "scattered snow"
      when 95 then "thunderstorms"
      when 96 then "thunderstorms and some hail"
      when 99 then "thunderstorms and heavy hail"
      end
    end
  end
end
