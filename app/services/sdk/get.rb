class SDK::Get < SDK::Verb
  def params(params = {})
    response = Faraday.get(@url + "?" + params.to_h.to_query) do |req|
      req.headers = all_headers
    end

    raise "Unexpected response: #{response.status} - #{response.body}" if !response.status.in? @statuses
    return response if response.status != 200

    JSON.parse(response.body, object_class: OpenStruct)
  end

  def headers(h)
    SDK::Get.new(@url, @bearer_token, h)
  end

  def expected_status(s)
    SDK::Get.new(@url, @bearer_token, @headers, Array(s))
  end
end
