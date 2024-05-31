class SDK::Get < SDK::Verb
  def param(params = {})
    response = Faraday.get(@url + "?" + params.to_h.to_query) do |req|
      req.headers = @headers
    end

    raise "Unexpected response: #{response.status} - #{response.body}" if !response.status.in? @expected_statuses
    return response if response.status != 200

    JSON.parse(response.body, object_class: OpenStruct)
  end
end
