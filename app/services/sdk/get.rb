class SDK::Get < SDK::Verb
  def params(params = {})
    response = Faraday.get(@url + "?" + encode(params)) do |req|
      req.headers["Authorization"] = "Bearer #{@bearer_token_proc.call}" if @bearer_token_proc.call
    end
    raise "Unexpected response: #{response.status} - #{response.body}" if response.status != 200
    JSON.parse(response.body, object_class: OpenStruct)
  end
end
