class SDK::Post < SDK::Verb
  def param(params = {})
    if @headers[:"Content-Type"] == "application/x-www-form-urlencoded"
      body = params.to_h.to_query
    else
      body = params.to_h.to_json
    end

    response = Faraday.post(@url) do |req|
      req.headers = @headers
      req.body = body
    end

    raise "Unexpected response: #{response.status} - #{response.body}" if !response.status.in? @expected_statuses
    return response if response.status != 200

    JSON.parse(response.body, object_class: OpenStruct)
  end
end
