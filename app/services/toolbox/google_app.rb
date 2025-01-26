module Toolbox::GoogleApp
  extend ActiveSupport::Concern

  def app_name
    self.class.to_s.gsub("Toolbox::", "").gsub(/(?<!\A)([A-Z])/, ' \1')
  end

  def refresh_token_if_needed(&block)
    2.times do |i|
      response = yield block
      expired_token   = response.is_a?(Faraday::Response) && response.status == 401
      if response.is_a?(Faraday::Response) && response.status == 403
        raise "Missing permissions. Tell the user to: Add your #{app_name} permissions again in your account settings."
      end

      refresh_token! && next if i == 0 && expired_token
      return response
    end
  end

  def refresh_token!
    if ! ::GoogleSDK.reauthenticate_credential(app_credential)
      raise "Gmail no longer connected"
    else
      true
    end
  end

  def uid
    app_credential&.oauth_id
  end

  def bearer_token
    token = app_credential&.oauth_token
    raise "Unable to find a user with valid credentials" unless token
    token
  end

  def header
    {
      content_type: "application/json",
      "Accept-Encoding": "gzip"
    }
  end

  def expected_status
    [200, 204, 401, 403]
  end
end
