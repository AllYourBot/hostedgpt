class SDK::Verb
  class ResponseError < StandardError
    attr_reader :status, :body, :response

    def initialize(response)
      @response = response
      @status = response.status
      @body = JSON.parse(response.body) rescue nil
      super("Unexpected response: #{response.status} - #{response.body}")
    end
  end

  def initialize(
    url:,
    bearer_token: nil,
    header: nil, # not using default value b/c we want to support nil being passed in to trigger default
    expected_status: nil,
    calling_method: nil
  )
    header ||= {}
    expected_status ||= [200]

    @url = url
    header.merge!({ Authorization: "Bearer #{bearer_token}" }) if bearer_token
    @headers = fix_keys(header)
    @expected_statuses = Array(expected_status)
    @calling_method = calling_method
  end

  def handle(response)
    raise ResponseError.new(response) if !response.status.in? @expected_statuses

    if response.status.between?(200, 299)
      body = decompress_body(response)
      body.presence && OpenData.for(JSON.parse(body)) rescue response
    end
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

  def no_params
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

  def get(url, &block)
    if self.class.respond_to?("mocked_response_get_#{@calling_method}")
      self.class.send("mocked_response_get_#{@calling_method}")
    else
      possible_test_warning(:get)
      Faraday.get(url, &block)
    end
  end

  def post(url, &block)
    if self.class.respond_to?("mocked_response_post_#{@calling_method}")
      self.class.send("mocked_response_post_#{@calling_method}")
    else
      possible_test_warning(:post)
      Faraday.post(url, &block)
    end
  end

  def patch(url, &block)
    if self.class.respond_to?("mocked_response_patch_#{@calling_method}")
      self.class.send("mocked_response_patch_#{@calling_method}")
    else
      possible_test_warning(:patch)
      Faraday.patch(url, &block)
    end
  end

  def delete(url, &block)
    if self.class.respond_to?("mocked_response_delete_#{@calling_method}")
      self.class.send("mocked_response_delete_#{@calling_method}")
    else
      possible_test_warning(:delete)
      Faraday.delete(url, &block)
    end
  end

  def possible_test_warning(verb)
    return if !Rails.env.test?
    return if self.class.send("allow_#{verb}_#{@calling_method}") rescue false

    Rails.logger.info "WARNING: live API call in test. USE: stub_#{verb}_response(:#{@calling_method}, status: ___, response: _______) do; ...; end"
  end

  def decompress_body(response)
    return response.body unless response.respond_to?(:headers) &&
                               response.headers["content-encoding"] == "gzip" &&
                               response.body.bytes[0..1] == [0x1f, 0x8b]
    begin
      Zlib::GzipReader.new(StringIO.new(response.body)).read
    rescue Zlib::GzipFile::Error
      response.body
    end
  end
end
