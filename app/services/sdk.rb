class SDK
  def get(url, token = nil)
    SDK::Get.new(
      url: url,
      bearer_token: token || bearer_token,
      expected_status: expected_status,
      header: header,
      calling_method: calling_method(__method__),
    )
  end

  def post(url, token = nil)
    SDK::Post.new(
      url: url,
      bearer_token: token || bearer_token,
      expected_status: expected_status,
      header: header,
      calling_method: calling_method(__method__),
    )
  end

  def patch(url, token = nil)
    SDK::Patch.new(
      url: url,
      bearer_token: token || bearer_token,
      expected_status: expected_status,
      header: header,
      calling_method: calling_method(__method__),
    )
  end

  def delete(url, token = nil)
    SDK::Delete.new(
      url: url,
      bearer_token: token || bearer_token,
      expected_status: expected_status,
      header: header,
      calling_method: calling_method(__method__),
    )
  end

  private

  def calling_method(verb)
    file = __FILE__
    i = caller_locations.find_index { |l| l.absolute_path&.starts_with?(file) && l.label == verb.to_s }
    raise "calling_method is blank" if i.nil?

    caller_locations[i+1]&.label&.gsub("block in ", "")
  end

  def key
    raise "self.key is undefined. You need to override this method."
  end

  def bearer_token
    nil
  end

  def expected_status
    nil
  end

  def header
    nil
  end

  def param
    nil
  end
end
