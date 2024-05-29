class SDK::Post < SDK::Verb
  def params(params = {})
    if all_headers[:"Content-Type"] == "application/x-www-form-urlencoded"
      body = params.to_h.to_query
    else
      body = params.to_h.to_json
    end

    response = Faraday.post(@url) do |req|
      req.headers = all_headers
      req.body = body
    end

    raise "Unexpected response: #{response.status} - #{response.body}" if !response.status.in? @statuses
    return response if response.status != 200

    JSON.parse(response.body, object_class: OpenStruct)
  end

  def headers(h)
    SDK::Post.new(@url, @bearer_token, h, @statuses)
  end

  def expected_status(s)
    SDK::Post.new(@url, @bearer_token, @headers, Array(s))
  end
end
