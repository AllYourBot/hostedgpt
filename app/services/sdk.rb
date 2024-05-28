class SDK
  def self.key
    raise "self.key is undefined. You need to override this method."
  end

  def self.get(url)
    SDK::Get.new(url)
  end

  def self.post(url, bearer_token_proc = ->{ nil })
    SDK::Post.new(url, bearer_token_proc)
  end
end
