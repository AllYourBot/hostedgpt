class Fly < SDK
  def key
    raise "self.key is undefined. You need to override this method."
  end

  def bearer_token
    `fly auth token`.chop
  end

  def get(url)
    SDK::Get.new(url, ->{ key }, ->{ bearer_token })
  end

  def post(url)
    SDK::Post.new(url, ->{ key }, ->{ bearer_token })
  end

  def patch(url)
    post(url)
  end
end
