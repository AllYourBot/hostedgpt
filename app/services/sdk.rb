class SDK
  private

  def key
    raise "self.key is undefined. You need to override this method."
  end

  def bearer_token
    nil
  end

  def get(url, token = nil)
    SDK::Get.new(url, token || bearer_token)
  end

  def post(url, token = nil)
    SDK::Post.new(url, token || bearer_token)
  end
end
