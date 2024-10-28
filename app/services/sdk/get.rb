class SDK::Get < SDK::Verb
  def param(params = {})
    hash = OpenData.new(params).to_h
    raise "Url contains a question mark, put that in params instead" if @url.include?("?")

    response = get(@url + "?" + hash.to_query) do |req|
      req.headers = @headers
    end

    handle(response)
  end
end
