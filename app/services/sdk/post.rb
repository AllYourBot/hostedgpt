class SDK::Post < SDK::Verb
  def params(params = {})
    response = Faraday.post(@url) do |req|
      req.headers["Authorization"] = "Bearer #{@bearer_token_proc.call}" if @bearer_token_proc.call
      req.body = better_to_hash(params).to_json
    end
    raise "Unexpected response: #{response.status} - #{response.body}" if response.status != 200
    JSON.parse(response.body, object_class: OpenStruct)
  end
end
