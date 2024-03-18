class JsonSerializer
  def self.dump(hash)
    JSON.parse(hash.deep_transform_values { |value| convert_value(value) }.to_json)
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