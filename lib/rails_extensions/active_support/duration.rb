module ActiveSupport
  class Duration
    def as_sentence
      # build simplifies the duration e.g. `{:seconds=>37090350}` becomes `{:years=>1, :months=>2, :days=>3, :hours=>4, :minutes=>5, :seconds=>6}`
      Duration.build(self.seconds).parts.
        map { |unit, v| "#{v} #{v == 1 ? unit.to_s.singularize : unit.to_s}" }.
        to_sentence
    end
  end
end
