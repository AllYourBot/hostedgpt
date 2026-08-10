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
    locations = caller_locations
    locations.each_with_index do |location, index|
      if bare_label(location) == verb.to_s
        # Return the method name from the next frame up
        return bare_label(locations[index + 1]) || "unknown"
      end
    end

    "unknown"
  end

  # Ruby >= 3.4 qualifies backtrace labels with the defining class, e.g. "SDK#get"
  # instead of just "get", and "block in Toolbox::Gmail#get_user_profile" instead of
  # "block in get_user_profile". Strip both so callers only see the bare method name.
  def bare_label(location)
    location&.label&.gsub("block in ", "")&.split("#")&.last
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
