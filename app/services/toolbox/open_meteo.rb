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

      current: "temperature_2m,apparent_temperature,precipitation,rain,showers,snowfall,cloud_cover",
      hourly:  "temperature_2m,apparent_temperature,precipitation_probability,precipitation,rain,showers,snowfall,snow_depth,cloud_cover",
      daily:   "temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,precipitation_sum,rain_sum,showers_sum,snowfall_sum,precipitation_probability_max",
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

    {
      in: "#{location.name}, #{location.admin1}, #{location.country}",

      right_now: "#{response.current.temperature_2m.round}#{degrees}",
      right_now_feels_like: "#{response.current.apparent_temperature.round}#{degrees}",

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
      best_index = pick_best_index(input: region_s, options: locations.map(&:admin1))
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
  end
end
