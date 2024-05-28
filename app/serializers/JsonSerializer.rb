class JsonSerializer
  def self.dump(object)
    transformed_object = deep_transform(object) { |value| convert_value(value) }
    transformed_object.to_json
  end

  def self.deep_transform(object, &block)
    case object
    when Hash
      object.transform_values { |value| deep_transform(value, &block) }
    when Array
      object.map { |value| deep_transform(value, &block) }
    else
      yield(object)
    end
  end

  def self.load(hash_or_json)
    case hash_or_json
    when String
      JSON.parse(hash_or_json, symbolize_names: true)
    when Hash
      hash_or_json.deep_symbolize_keys
    else
      {}
    end
  end

  def self.convert_value(value)
    case value
    when 'true'
      true
    when 'false'
      false
    else
      value
    end
  end
end