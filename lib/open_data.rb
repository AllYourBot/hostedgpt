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
    recurcive_to_h(self)
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

  private

  def parse_hash(hash)
    key = hash.keys.map(&:to_sym)
    @@data_classes[key] ||= Data.define(*key)

    values = hash.transform_values do |value|
      value.is_a?(Hash) ? self.class.new(value) : value
    end
    @@data_classes[key].new(**values)
  end

  def recurcive_to_h(os)
    if os.is_a?(OpenData)
      os.instance_variable_get(:@data).to_h.transform_values do |val|
        recurcive_to_h(val)
      end
    elsif os.is_a?(Array)
      os.map do |val|
        recurcive_to_h(val)
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

  def inspect
    @data.inspect.gsub('<data', '<OpenData')
  end
end
