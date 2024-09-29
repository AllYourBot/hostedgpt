ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/autorun"
require "pry"
require "capybara/rails"
require "capybara/minitest"

Dir[Rails.root.join("test/support/**/*.rb")].sort.each { |file| require file }

Dir[File.join(Rails.root, "lib", "rails_extensions", "**/*.rb")].each do |path|
  require path
end

class Capybara::Node::Element
  def obsolete?
    inspect.include?("Obsolete")
  end

  def exists?
    !obsolete?
  end
end

Capybara.register_driver :selenium_chrome_headless do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.add_argument("--headless")
    # opts.add_argument("--disable-gpu") if Gem.win_platform?
    # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
    # opts.add_argument("--disable-site-isolation-trials")
    # opts.add_argument("--window-size=1920,1080")
    # opts.add_argument("--disable-search-engine-choice-screen")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--window-size=1400,800") # your desired window size

    opts.browser_version = "127"
  end

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

class ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  Capybara.default_max_wait_time = 10

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
