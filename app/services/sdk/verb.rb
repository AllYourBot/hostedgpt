class SDK::Verb
  def initialize(url, key_proc, bearer_token_proc)
    @url = url
    @key_proc = key_proc
    @bearer_token_proc = bearer_token_proc
  end

  def no_params
    params
  end

  def encode(params)
    params.map do |key, val|
      "#{key}=#{CGI.escape(val.to_s)}"
    end.join("&")
  end

  def better_to_hash(os)
    if os.is_a?(OpenStruct) || os.is_a?(Hash)
      os.to_h.transform_values do |val|
        better_to_hash(val)
      end
    elsif os.is_a?(Array)
      os.map do |val|
        better_to_hash(val)
      end
    else
      os
    end
  end
end
