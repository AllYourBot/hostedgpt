module AIBackend::Utilities
  extend ActiveSupport::Concern

  included do
    private

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
