class Toolbox::OpenMeteo < Toolbox
  # Followed this guide: https://open-meteo.com/en/docs

  describe :get_current_and_todays_weather, <<~S
    Query the current weather and today's forecast for a given location. The location must be specified with a valid city
    and a valid state_province_or_region. The city and state_province_or_region SHOULD NEVER BE INFERRED; meaning, you should
    ask the user to clarify their city or clarify their state_province_or_region if you have not been instructed with those.
  S

  def get_current_and_todays_weather(city_s:, state_province_or_region_s:, country_s: nil)
    location = get_location(city_s, state_province_or_region_s, country_s)

    response = get("https://api.open-meteo.com/v1/forecast").param(
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

    d = extract_data_from(response)

    near_high = (d.today_high - d.curr) <= 2
    near_low = (d.curr - d.today_low) <= 2

    if near_high
      phrase = "at today's high of "
      near_low = false
    elsif near_low
      phrase = "at today's low of "
    else
      phrase = ""
    end

    summary = "Currently in #{location.name} there "
    summary += weather_code_to_description(d.curr_code).join(' ') # "are scattered showers"
    summary += " and it's #{phrase}#{d.curr.round} degrees"

    if d.curr_feel - d.curr >= 5
      summary += ", but it feels like #{d.curr_feel.round} degrees. "
    else
      summary += ". "
    end

    if d.today_code != d.curr_code
      summary += "Today "
      summary += weather_code_to_description(d.today_code).reverse.join(' ') + " forecasted with a "
    else
      summary += "Today there's a forecasted "
    end

    summary += "low of #{d.today_low.round} degrees" if (!near_low)
    summary += " and a " if (!near_high && !near_low)
    summary += "high of #{d.today_high.round} degrees" if (!near_high)

    if d.today_high_feel - d.today_high >= 5
      summary += ", but it will feel like #{d.today_high_feel.round} degrees."
    else
      summary += "."
    end

    {
      date: Date.current.strftime("%Y-%m-%d"),
      in: "#{location.name}, #{location.admin1}, #{location.country}",

      right_now: format(d.curr.round, d.degrees_unit),
      right_now_feels_like: format(d.curr_feel, d.degrees_unit),

      right_now_precipitation: format(d.curr_precip, d.qty_unit),
      right_now_rain: format(d.curr_rain, d.qty_unit),
      right_now_showers: format(d.curr_showers, d.qty_unit),
      right_now_snowfall: format(d.curr_snowfall, d.qty_unit),
      right_now_cloud_cover: format(d.curr_cloud_cover, '%'),

      today_high: format(d.today_high.round, d.degrees_unit),
      today_high_feels_like: format(d.today_high_feel.round, d.degrees_unit),
      today_low: format(d.today_low.round, d.degrees_unit),
      today_low_feels_like: format(d.today_low_feel.round, d.degrees_unit),

      today_high_change_from_yesterday: "#{d.today_high > d.yest_high ? "+" :''}#{(d.today_high - d.yest_high).round(1)} #{d.degrees_unit}",
      today_high_feels_like_change_from_yesterday: "#{d.today_high_feel > d.yest_high_feel ? "+" :''}#{(d.today_high_feel - d.yest_high_feel).round(1)} #{d.degrees_unit}",
      today_low_change_from_yesterday: "#{d.today_low > d.yest_low ? "+" :''}#{(d.today_low - d.yest_low).round(1)} #{d.degrees_unit}",
      today_low_feels_like_change_from_yesterday: "#{d.today_low_feel > d.yest_low_feel ? "+" :''}#{(d.today_low_feel - d.yest_low_feel).round(1)} #{d.degrees_unit}",

      today_precipitation: format(d.today_precip, d.qty_unit),
      today_precipitation_probability: format(d.today_precip_prob, '%'),
      today_rain: format(d.today_rain, d.qty_unit),
      today_showers: format(d.today_showers, d.qty_unit),
      today_snowfall: format(d.today_snowfall, d.qty_unit),

      good_summary: summary,
      right_now_weather_code: d.curr_code,
      today_weather_code: d.today_code,
    }
  end

  describe :get_historical_weather, <<~S
    Query the NOAA historical weather for a given location on a given date or range of dates. Query any time you are asked questions
    about past weather. You should NEVER answer questions about past weather from your existing knowledge, instead ALWAYS confirm
    questions about past weather by querying weather data. The location must be specified with a valid city and a valid
    state_province_or_region. The city and state_province_or_region SHOULD NEVER BE INFERRED; meaning, you should
    ask the user to clarify their city or clarify their state_province_or_region if you have not been instructed with those. You CAN INFER
    dates based on the conversation. However, the query date range should NEVER span more than 12 months (or 52 weeks). If you need to
    query data spanning a longer period, do multiple queries for the SPECIFIC narrow ranges you want to consider.
  S

  def get_historical_weather(city_s:, state_province_or_region_s:, country_s:  nil, date_span_begin_s:, date_span_end_s:)
    location = get_location(city_s, state_province_or_region_s, country_s)

    date_begin = Date.parse(date_span_begin_s).beginning_of_day
    date_end = Date.parse(date_span_end_s).beginning_of_day

    if date_begin == date_end &&
      date_begin.in?([ Date.today.beginning_of_day, (Date.today - 1.day).beginning_of_day ])

      return get_current_and_todays_weather(city_s: city_s, state_province_or_region_s: state_province_or_region_s, country_s: country_s)
    end

    raise "date_span_begin should be older than date_span_end" if date_end < date_begin
    span = ((date_end.to_i - date_begin.to_i) / 30.days.to_f)
    raise "You attempted to query for more than 12 months" if span > 12.0

    data = get("https://archive-api.open-meteo.com/v1/archive").param(
      latitude: location.latitude,
      longitude: location.longitude,
      timezone: location.timezone,

      start_date: date_begin.to_date.strftime("%Y-%m-%d"),
      end_date: date_end.to_date.strftime("%Y-%m-%d"),

      temperature_unit: "fahrenheit",
      wind_speed_unit: "mph",
      precipitation_unit: "inch",

      daily: "weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,precipitation_sum,rain_sum,snowfall_sum",
    )

    degrees_unit = unit(data.daily_units.temperature_2m_max)
    qty_unit = unit(data.daily_units.precipitation_sum)
    dailies = data.daily

    dailies.time.map.with_index do |date, i|
      day = dailies.to_h.transform_values { |v| v[i] }
      {
        date: day[:time],
        in: "#{location.name}, #{location.admin1}, #{location.country}",

        temp_high: day[:temperature_2m_max],
        temp_high_feels_like: day[:apparent_temperature_max],
        temp_low: day[:temperature_2m_max],
        temp_low_feels_like: day[:apparent_temperature_min],

        temp_high_formatted: format(day[:temperature_2m_max], degrees_unit),
        temp_high_feels_like_formatted: format(day[:apparent_temperature_max], degrees_unit),
        temp_low_formatted: format(day[:temperature_2m_max], degrees_unit),
        temp_low_feels_like_formatted: format(day[:apparent_temperature_min], degrees_unit),

        precipitation: day[:precipitation_sum],
        rain: day[:rain_sum],
        snowfall: day[:snowfall_sum],

        precipitation_formatted: format(day[:precipitation_sum], qty_unit),
        rain_formatted: format(day[:rain_sum], qty_unit),
        snowfall_formatted: format(day[:snowfall_sum], qty_unit),
      }
    end
  end

  private

  def get_location(city_s, state_province_or_region_s, country_s = nil)
    locations = get("https://geocoding-api.open-meteo.com/v1/search").param(
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

  def extract_data_from(response)
    OpenData.new({
      degrees_unit: unit(response.current_units.temperature_2m),
      qty_unit: unit(response.current_units.precipitation),
      yest_high: response.daily.temperature_2m_max[0],
      yest_high_feel: response.daily.apparent_temperature_max[0],
      yest_low: response.daily.temperature_2m_min[0],
      yest_low_feel: response.daily.apparent_temperature_min[0],

      today_high: response.daily.temperature_2m_max[1],
      today_high_feel: response.daily.apparent_temperature_max[1],
      today_low: response.daily.temperature_2m_min[1],
      today_low_feel: response.daily.apparent_temperature_min[1],

      curr: response.current.temperature_2m,
      curr_feel: response.current.apparent_temperature,

      curr_precip: response.current.precipitation,
      curr_rain: response.current.rain,
      curr_showers: response.current.showers,
      curr_snowfall: response.current.snowfall,

      curr_cloud_cover: response.current.cloud_cover,

      today_precip: response.daily.precipitation_sum[1],
      today_precip_prob: response.daily.precipitation_probability_max[1],

      today_rain: response.daily.rain_sum[1],
      today_showers: response.daily.showers_sum[1],
      today_snowfall: response.daily.snowfall_sum[1],

      curr_code: response.current.weather_code,
      today_code: response.daily.weather_code[1],
    })
  end

  def unit(u)
    u.gsub('°', 'degrees ').gsub('F', 'fahrenheit').gsub('C', 'celcius')
  end

  def weather_code_to_description(code)
    # it's 85 degrees with
    case code
    when 0 then ["are", "clear skies"]
    when 1 then ["are", "mostly clear skies"]
    when 2 then ["are", "scattered clouds"]
    when 3 then ["are", "overcast skies"]
    when 45 then ["is", "fog"]
    when 48 then ["is", "freezing fog"]
    when 51 then ["is", "light drizzle"]
    when 53 then ["is", "drizzle"]
    when 55 then ["is", "heavy drizzle"]
    when 56 then ["is", "light freezing drizzle"]
    when 57 then ["is", "freezing drizzle"]
    when 61 then ["is", "light rain"]
    when 63 then ["is", "rain"]
    when 65 then ["is", "heavy rain"]
    when 66 then ["is", "light freezing rain"]
    when 67 then ["is", "freezing rain"]
    when 71 then ["is", "light snow"]
    when 73 then ["is", "snow"]
    when 75 then ["is", "heavy snow"]
    when 77 then ["is", "snow drizzle"]
    when 80 then ["are", "light scattered showers"]
    when 81 then ["are", "scattered showers"]
    when 82 then ["are", "heavy scattered showers"]
    when 85 then ["are", "light scattered snow"]
    when 86 then ["are", "scattered snow"]
    when 95 then ["are", "some thunderstorms"]
    when 96 then ["are", "thunderstorms and some hail"]
    when 99 then ["are", "thunderstorms and heavy hail"]
    end
  end

  def format(num, unit)
    if unit.include?('celcius')
      (num * 2).round / 2.0
    elsif unit.include?('fahrenheit')
      num.round
    elsif unit.include?('in')
      (num.round * 4).round / 4.0
    elsif unit.include?('cm')
      num.round
    elsif unit.include?('%')
      num
    else
      num.round
    end.to_s + " " + unit
  end
end
