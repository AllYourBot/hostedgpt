module ActiveSupport
  class Duration
    def as_sentence
      units = [:days, :hours, :minutes]
      map   = {
        :days     => { :one => :d, :other => :days },
        :hours    => { :one => :h, :other => :hours },
        :minutes  => { :one => :m, :other => :minutes }
      }

      parts.
        sort_by { |unit, _| units.index(unit) }.
        map     { |unit, val| "#{val} #{val == 1 ? map[unit][:one].to_s : map[unit][:other].to_s}" }.
        to_sentence
    end
  end
end
