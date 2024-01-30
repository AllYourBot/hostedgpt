ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "pry"
require "webmock/minitest"
require "mocha/minitest"

IS_FULL_TEST_RUN = ARGV.none? { |arg| arg.include?("_test.rb") || arg.include?("test/") }

if IS_FULL_TEST_RUN
  require "simplecov"

  SimpleCov.start "rails" do
    add_filter do |source_file|
      next unless source_file.lines.count > 0
      source_file.lines.first.src =~ /# ignore simplecov/i ||
        source_file.filename =~ /application_.*\.rb/
    end
  end

  SimpleCov.at_exit do
    SimpleCov.result.format!
    zero_coverage_files = SimpleCov.result.files.select { |file| file.covered_percent == 0 }
    if zero_coverage_files.any?
      puts ""
      puts "WARNING: #{zero_coverage_files.length} files with zero tests. Add this comment to the top of any file you never plan to add tests for: # ignore simplecov"
      puts ""
      root_path = Rails.root.to_s + "/"
      zero_coverage_files.each do |file|
        puts file.filename.sub(root_path, "")
      end

      puts ""
      puts "WARNING: #{zero_coverage_files.length} files have no tests. ^ Can you test any of them?"
      puts ""
    end
  end
end

class ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  def login_as(user)
    post login_path, params: { email: user.person.email, password: "secret" }
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end
end

module ActiveSupport
  class TestCase
    include Turbo::Broadcastable::TestHelper
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    def setup
      WebMock.enable!
    end

    def teardown
      WebMock.disable!
    end
  end
end
