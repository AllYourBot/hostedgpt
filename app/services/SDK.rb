class SDK
  def self.key
    raise "self.key is undefined. You need to override this method."
  end

  def self.get(url)
    response = Faraday.get(url)
    binding.pry if response.status != 200
    raise "Unexpected response: #{response.status} - #{response.body}" if response.status != 200
    JSON.parse(response.body, object_class: OpenStruct)
  end
end
