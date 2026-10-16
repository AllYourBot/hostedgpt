module AppURL
  # Without a configured app URL, links stay relative: development and test have
  # no host, and only_path fixes an exception with attachment URL generation from
  # a worker: https://github.com/AllYourBot/hostedgpt/pull/398#issuecomment-2168135853
  def self.options
    config = Rails.application.config.x
    return { only_path: true } if config.app_url.blank?

    { protocol: config.app_url_protocol, host: config.app_url_host, port: config.app_url_port }
  end
end
