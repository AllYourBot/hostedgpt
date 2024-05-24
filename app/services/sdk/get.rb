class SDK::Get
  def initialize(url)
    @url = url
  end

  def params(params)
    response = Faraday.get(@url + "?" + encode(params))
    raise "Unexpected response: #{response.status} - #{response.body}" if response.status != 200
    JSON.parse(response.body, object_class: OpenStruct)
  end

  def encode(params)
    params.map do |key, val|
      "#{key}=#{CGI.escape(val.to_s)}"
    end.join("&")
  end
end
