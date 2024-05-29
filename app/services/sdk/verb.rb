class SDK::Verb
  def initialize(url, bearer_token = nil, headers = {}, statuses = [200])
    @url = url
    @bearer_token = bearer_token
    @headers = reformat(headers)
    @statuses = statuses
  end

  def no_params
    params
  end

  private

  def all_headers
    @headers["Authorization"] = "Bearer #{@bearer_token}" if @bearer_token && @headers["Authorization"].blank?
    @headers
  end

  def reformat(headers)
    h = headers.symbolize_keys
    if (content_type = h.delete(:content_type))
      h[:'Content-Type'] = content_type
    end
    h
  end
end
