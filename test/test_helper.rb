ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/autorun"
require "pry"
require "selenium-webdriver"
Dir[Rails.root.join("test/support/**/*.rb")].sort.each { |file| require file }

class Capybara::Node::Element
  def obsolete?
    inspect.include?("Obsolete")
  end

  def exists?
    !obsolete?
  end
end

# module Selenium
#   module WebDriver
#     module Chrome
#       class Service
#         alias_method :old_start, :start
#         def start
#           @process.io.stdout = Tempfile.new("chromdriver-output")
#           old_start
#         end
#       end
#     end
#   end
# end
Selenium::WebDriver.logger.level = :info
Selenium::WebDriver.logger.output = "/tmp/selenium.log"

class ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  Capybara.default_max_wait_time = 10

  # # Capybara.register_driver :headless_chrome do |app|
  # Capybara.register_driver :chrome do |app|
  #   # increase timeout for slow CI
  #   client = Selenium::WebDriver::Remote::Http::Default.new
  #   client.read_timeout = 120

  #   # options = Selenium::WebDriver::Chrome::Options.new(args: %w[headless disable-gpu no-sandbox])
  #   # Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, http_client: client)
  #   Capybara::Selenium::Driver.new(app, browser: :chrome, http_client: client)
  # end

  # Webdrivers::Chromedriver.required_version = "127.0.6533.88"
  # Webdrivers::Chromedriver.update


  # Capybara.register_driver :headless_chrome  do |app|

  #   # capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
  #   options = Selenium::WebDriver::Chrome::Options.new(
  #     args: %w[headless=new no-sandbox disable-dev-shm-usage remote-debugging-pipe log-path=/tmp/chrome.log],
  #     timeout: 120
  #   )

  #   client = Selenium::WebDriver::Remote::Http::Default.new
  #   client.read_timeout = 120

  #   Capybara::Selenium::WebDriver.new(
  #     app,
  #     browser: :chrome,
  #     # desired_capabilities: capabilities
  #     options: options,
  #   )
  #   # Capybara::Selenium::WebDriver.for(:chrome, options: options)
  # end

  # Capybara.javascript_driver = :headless_chrome
  # Capybara.current_driver = :headless_chrome

  Capybara.register_driver :headless_chrome do |app|
    version = Capybara::Selenium::Driver.load_selenium
    options_key = Capybara::Selenium::Driver::CAPS_VERSION.satisfied_by?(version) ? :capabilities : :options
    browser_options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
      opts.add_argument("--headless=new")
      opts.add_argument("--disable-gpu")
      opts.add_argument("--no-sandbox")
      opts.add_argument("--disable-dev-shm-usage")
      opts.add_argument("--remote-debugging-pipe")
      opts.add_argument("--remote-debugging-port=9222")
      opts.add_argument("--window-size=1920,1080")
      opts.add_argument("--disable-features=VizDisplayCompositor")
      opts.add_argument("--disable-site-isolation-trials")
      opts.add_argument("--disable-popup-blocking")
      opts.add_argument("--disable-extensions")
      opts.add_argument("--disable-infobars")
      opts.add_argument("--disable-notifications")
      opts.add_argument("--disable-offer-store-unmasked-wallet-cards")
      opts.add_argument("--disable-offer-upload-credit-cards")
      opts.add_argument("--disable-features=site-per-process")
      opts.add_argument("--disable-features=NetworkService")
      opts.add_argument("--disable-features=NetworkServiceInProcess")
      opts.add_argument("--disable-features=VizDisplayCompositor")
      opts.add_argument("--disable-features=IsolateOrigins")
      # set log path
      opts.add_argument("--log-file=#{Rails.root.join('log', 'chrome.log')}")
      opts.add_argument("--log-level=0")

      # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
      opts.add_argument("--disable-site-isolation-trials")
      opts.add_preference("download.default_directory", Capybara.save_path)
      opts.add_preference(:download, default_directory: Capybara.save_path)
    end

    Capybara::Selenium::Driver.new(app, **{ browser: :chrome, options_key => browser_options })
  end




  def login_as(user_or_person, password = "secret")
    user = if user_or_person.is_a?(Person)
      user_or_person.user
    else
      user_or_person
    end
    post login_path, params: { email: user.email, password: password }
    assert_response :redirect
    follow_redirect! # root
    follow_redirect! # conversation
    assert_response :success
  end

  def assert_logged_in(user = nil)
    client = Client.find_by(token: session.fetch(:client_token))
    if user.nil?
      assert_nil client&.person&.user
    else
      assert_equal client&.person&.user, user
    end
  end
end

module ActiveSupport
  class TestCase
    include Turbo::Broadcastable::TestHelper
    include ActiveJob::TestHelper
    include OptionsHelpers, PostgresqlHelper, ViewHelpers, SDKHelpers

    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end
