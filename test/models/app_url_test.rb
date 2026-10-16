require "test_helper"

class AppURLTest < ActiveSupport::TestCase
  test "options are relative when no app URL is configured" do
    stub_custom_config_value(:app_url, nil)
    assert_equal({ only_path: true }, AppURL.options, "Without an app URL, links should stay relative")
  end

  test "options carry the configured protocol, host, and port" do
    stub_custom_config_value(:app_url, "https://example.com:8443")
    stub_custom_config_value(:app_url_protocol, "https")
    stub_custom_config_value(:app_url_host, "example.com")
    stub_custom_config_value(:app_url_port, "8443")
    assert_equal({ protocol: "https", host: "example.com", port: "8443" }, AppURL.options, "Options should come from the app URL settings")
  end
end
