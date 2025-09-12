class SDK
  def get(url, token = nil)
    SDK::Get.new(
      url:,
      bearer_token: token || bearer_token,
      expected_status:,
      header:,
      calling_method: calling_method(__method__),
    )
  end

  def post(url, token = nil)
    SDK::Post.new(
      url:,
      bearer_token: token || bearer_token,
      expected_status:,
      header:,
      calling_method: calling_method(__method__),
    )
  end

  def patch(url, token = nil)
    SDK::Patch.new(
      url:,
      bearer_token: token || bearer_token,
      expected_status:,
      header:,
      calling_method: calling_method(__method__),
    )
  end

  def delete(url, token = nil)
    SDK::Delete.new(
      url:,
      bearer_token: token || bearer_token,
      expected_status:,
      header:,
      calling_method: calling_method(__method__),
    )
  end

  private

  def calling_method(verb)
    # Find the method that called get/post/patch/delete
    # Look through the stack to find the actual method name
    caller_locations.each_with_index do |location, index|
      if location.label == verb.to_s
        # Return the method name from the next frame up
        return caller_locations[index + 1]&.label&.gsub("block in ", "") || "unknown"
      end
    end

    "unknown"
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
