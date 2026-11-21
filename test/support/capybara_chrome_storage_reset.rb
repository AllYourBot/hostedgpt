# Chrome 158 rejects the wildcard origin Capybara 3.40's reset! passes ("* is not a valid URL"): teamcapybara/capybara#2865
module CapybaraChromeStorageReset
  private

  def execute_cdp(cmd, params = {})
    return super unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

    types = params[:storageTypes].to_s.split(",")
    super("Network.clearBrowserCookies") if types.delete("cookies")

    origin = Capybara.current_session.server&.base_url
    super(cmd, params.merge(origin: origin, storageTypes: types.join(","))) if origin && types.any?
  end
end

if Gem.loaded_specs["capybara"]&.version == Gem::Version.new("3.40.0")
  require "capybara/selenium/driver"
  Capybara::Selenium::Driver::ChromeDriver.prepend(CapybaraChromeStorageReset)
end
