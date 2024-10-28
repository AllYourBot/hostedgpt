module AIBackend::Utilities
  extend ActiveSupport::Concern

  included do
    private

    def deep_streaming_merge(hash1, hash2)
      merged_hash = hash1.dup
      hash2.each do |key, value|
        if merged_hash.has_key?(key) && merged_hash[key].is_a?(Hash) && value.is_a?(Hash)
          merged_hash[key] = deep_streaming_merge(merged_hash[key], value)
        elsif merged_hash.has_key?(key)
          merged_hash[key] += value
        else
          merged_hash[key] = value
        end
      end
      merged_hash
    end

    def self.deep_json_parse(obj)
      if obj.is_a?(Array)
        obj.map { |item| deep_json_parse(item) }
      else
        converted_hash = {}
        obj.each do |key, value|
          if value.is_a?(Hash)
            converted_hash[key] = deep_json_parse(value)
          else
            converted_hash[key] = begin
              JSON.parse(value)
            rescue => e
              value
            end
          end
        end
        converted_hash
      end
    end
  end
end
