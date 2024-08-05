ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/autorun"
require "pry"
Dir[Rails.root.join("test/support/**/*.rb")].sort.each { |file| require file }

class Capybara::Node::Element
  def obsolete?
    inspect.include?("Obsolete")
  end

  def exists?
    !obsolete?
  end
end

class ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  # Capybara.register_driver :selenium_with_long_timeout do |app|
  #   client = Selenium::WebDriver::Remote::Http::Default.new(open_timeout: 180, read_timeout: 180)
  #   Capybara::Driver::Selenium.new(app, :http_client => client)
  # end
  # Capybara.javascript_driver = :selenium_with_long_timeout

  # Capybara.default_max_wait_time = 10


    #   def self.driven_by(driver, using: :chrome, screen_size: [1400, 1400], options: {}, &capabilities)
    #   driver_options = { using: using, screen_size: screen_size, options: options }

    #   self.driver = SystemTesting::Driver.new(driver, **driver_options, &capabilities)
    # end



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
