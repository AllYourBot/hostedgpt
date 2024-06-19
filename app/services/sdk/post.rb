class SDK::Post < SDK::Verb
  def param(params = {})
    hash = OpenData.new(params).to_h
    if @headers[:"Content-Type"] == "application/x-www-form-urlencoded"
      body = hash.to_query
    else
      body = hash.to_json
    end

    response = Faraday.post(@url) do |req|
      req.headers = @headers
      req.body = body
    end

    raise "Unexpected response: #{response.status} - #{response.body}" if !response.status.in? @expected_statuses
    return response if response.status != 200

    OpenData.new JSON.parse(response.body)
  end
end
