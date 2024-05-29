class OpenStruct
  alias_method :original_to_h, :to_h

  def to_h
    better_to_hash(self)
  end

  def keys
    to_h.keys
  end

  def values
    to_h.values
  end

  def inspect
    "#<OpenStruct #{to_h.to_s.gsub('=>', ': ')}>"
  end

  private

  def better_to_hash(os)
    if os.is_a?(OpenStruct) || os.is_a?(Hash)
      os.original_to_h.transform_values do |val|
        better_to_hash(val)
      end
    elsif os.is_a?(Array)
      os.map do |val|
        better_to_hash(val)
      end
    else
      os
    end
  end
end
