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


  Capybara.register_driver :headless_chrome  do |app|

    # capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    options = Selenium::WebDriver::Chrome::Options.new(
      args: %w[headless=new no-sandbox disable-dev-shm-usage remote-debugging-pipe log-path=/tmp/chrome.log]
    )

    client = Selenium::WebDriver::Remote::Http::Default.new
    client.read_timeout = 120

    Capybara::Selenium::WebDriver.new(
      app,
      browser: :chrome,
      # desired_capabilities: capabilities
      options: options,
    )
    # Capybara::Selenium::WebDriver.for(:chrome, options: options)
  end

  # Capybara.javascript_driver = :headless_chrome
  # Capybara.current_driver = :headless_chrome




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
