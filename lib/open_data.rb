class OpenData
  @@data_classes = {}

  def initialize(input)
    if input.is_a?(Hash)
      @data = parse_hash(input)
    else
      begin
        @data = parse_hash(JSON.parse(input))
      rescue JSON::ParserError
        raise "OpenData either needs a hash or valid JSON string"
      end
    end
  end

  def to_h
    recursive_to_h(self)
  end

  def keys
    to_h.keys
  end

  def values
    to_h.values
  end

  def merge!(input)
    @data = parse_hash(self.to_h.merge(input.to_h))
    self
  end

  def merge(input)
    OpenData.new(self.to_h.merge(input.to_h))
  end

  def ==(other)
    to_h == other.to_h
  end

  def eql?(other)
    self == other
  end

  def inspect
    @data.inspect.gsub('<data', '<OpenData')
  end

  private

  def parse_hash(hash)
    key = hash.keys.map(&:to_sym)
    @@data_classes[key] ||= Data.define(*key)

    values = hash.transform_values do |value|
      parse_value(value)
    end
    @@data_classes[key].new(**values)
  end

  def parse_value(value)
    if value.is_a?(Hash)
      self.class.new(value)
    elsif value.is_a?(Array)
      value.map { |v| parse_value(v) }
    else
      value
    end
  end

  def recursive_to_h(os)
    if os.is_a?(OpenData)
      os.instance_variable_get(:@data).to_h.transform_values do |val|
        recursive_to_h(val)
      end
    elsif os.is_a?(Array)
      os.map do |val|
        recursive_to_h(val)
      end
    else
      os
    end
  end

  def method_missing(method_name, *arguments, &block)
    if OpenData.instance_methods.include?(method_name) || OpenData.private_instance_methods.include?(method_name)
      super
    else
      @data.send(method_name, *arguments, &block)
    end
  end
end
