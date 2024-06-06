module Client::TimeZoneable
  extend ActiveSupport::Concern

  included do
    def time_zone_offset_in_hours
      return nil if time_zone_offset_in_minutes.nil?
      (time_zone_offset_in_minutes.to_i / 60.0).round(1)
    end

    def utc_offset
      return nil if time_zone_offset_in_minutes.nil?
      sym = time_zone_offset_in_minutes.to_i > 0 ? '+' : '-'
      hr = time_zone_offset_in_minutes.to_i / 60
      min = time_zone_offset_in_minutes.to_i % 60

      "%s%02d:%02d" % [sym, hr.abs, min]
    end

    def current_time
      return nil if time_zone_offset_in_minutes.nil?
      DateTime.now.new_offset(Rational(time_zone_offset_in_hours,24))
    end

    def current_hour_in_device_time_zone
      return nil if time_zone_offset_in_minutes.blank?

      utc_hour = Time.current.utc.hour
      hour = utc_hour + (time_zone_offset_in_minutes / 60).to_i
      hour = 0 if hour == 24

      hour
    end
  end
end