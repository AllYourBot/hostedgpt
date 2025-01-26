ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/autorun"
require "minitest/retry"
require "webmock/minitest"

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

Minitest::Retry.use!(
  retry_count: 1,
  verbose: true,
  exceptions_to_retry: [Net::ReadTimeout, Minitest::Assertion]
)

class ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  Capybara.default_max_wait_time = 10

  WebMock.disable_net_connect!(allow_localhost: true)


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
    include OptionsHelpers, ViewHelpers, SDKHelpers, ConfigHelpers

    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end

class ActionDispatch::SystemTestCase
  parallelize(workers: Etc.nprocessors/2)
end
