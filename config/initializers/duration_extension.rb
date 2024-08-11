ActiveSupport::Duration.class_eval do
  def as_sentence
    Duration.build(self.seconds).parts.
      map { |unit, v| "#{v} #{v == 1 ? unit.to_s.singularize : unit.to_s}" }.
      to_sentence
  end
end
