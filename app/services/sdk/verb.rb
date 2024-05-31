class SDK::Verb
  def initialize(
    url:,
    bearer_token: nil,
    header: nil, # not using default value b/c we want to support nil being passed in to trigger default
    expected_status: nil
  )
    header ||= {}
    expected_status ||= [200]

    @url = url
    header.merge!({ Authorization: "Bearer #{bearer_token}" }) if bearer_token
    @headers = fix_keys(header)
    @expected_statuses = Array(expected_status)
  end

  def json_content
    header(content_type: "application/json")
  end

  def www_content
    header(content_type: "application/x-www-form-urlencoded")
  end

  def header(h)
    raise "Header expects a hash" unless h.is_a?(Hash)
    self.class.new(**smart_merge(args, { header: fix_keys(h) }))
  end

  def expected_status(s)
    raise "Expected status expects an integer or array of integers" unless s.is_a?(Integer) || s.is_a?(Array)
    self.class.new(**smart_merge(args, { expected_status: s }))
  end

  def no_param
    param
  end

  private

  def fix_keys(headers)
    h = headers.symbolize_keys
    if (content_type = h.delete(:content_type))
      h[:'Content-Type'] = content_type
    end
    h
  end

  def args
    {
      url: @url,
      header: @headers,
      expected_status: @expected_statuses,
    }
  end

  def smart_merge(hash1, hash2)
    merged_hash = hash1.dup
    hash2.each do |key, value|
      if merged_hash.has_key?(key) && merged_hash[key].is_a?(Hash) && value.is_a?(Hash)
        merged_hash[key] = smart_merge(merged_hash[key], value)
      elsif merged_hash.has_key?(key) && merged_hash[key].is_a?(Array) && value.is_a?(Integer)
        merged_hash[key] = (merged_hash[key] + [value]).uniq
      else
        merged_hash[key] = value
      end
    end
    merged_hash
  end
end
