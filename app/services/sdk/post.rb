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

    handle(response)
  end
end
