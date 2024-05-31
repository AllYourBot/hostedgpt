class SDK
  def get(url, token = nil)
    SDK::Get.new(
      url: url,
      bearer_token: token || bearer_token,
      expected_status: expected_status,
      header: header
    )
  end

  def post(url, token = nil)
    SDK::Post.new(
      url: url,
      bearer_token: token || bearer_token,
      expected_status: expected_status,
      header: header
    )
  end

  private

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
