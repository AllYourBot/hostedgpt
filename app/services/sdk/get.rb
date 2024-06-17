class SDK::Get < SDK::Verb
  def param(params = {})
    hash = OpenData.new(params).to_h
    response = Faraday.get(@url + "?" + hash.to_query) do |req|
      req.headers = @headers
    end

    handle(response)
  end
end
