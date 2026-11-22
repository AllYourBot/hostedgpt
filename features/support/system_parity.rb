# frozen_string_literal: true

# Parity infrastructure so cucumber drives the app the same way the minitest
# system suite does. The values and mechanics mirror test/test_helper.rb and
# test/application_system_test_case.rb.

# Mirror ActiveJob::TestHelper: without the test adapter, every ported
# "send a message" scenario enqueues GetNextAIMessageJob onto the async
# adapter, which would fire a real AI provider call.
require "minitest/mock"
ActiveJob::Base.queue_adapter = :test

# Mirror test_helper.rb: no outbound HTTP from the app process (localhost is
# allowed for Capybara's server and ActionCable). Any stray synchronous
# external call fails loudly instead of reaching a real API.
require "webmock/minitest"
WebMock.disable_net_connect!(allow_localhost: true)

# test_helper.rb sets 10 for the minitest suite; match it.
Capybara.default_max_wait_time = 10

# The element monkey-patches the minitest suite defines (test/test_helper.rb
# and test/application_system_test_case.rb) so steps can use the same helpers.
class Capybara::Node::Element
  def obsolete? = inspect.include?("Obsolete")

  def exists? = !obsolete?

  def find_role(label) = find("[data-role='#{label}']", visible: :all)

  def find_target(label, controller:) = find("[data-#{controller}-target='#{label}']", visible: :all)
end

# Headless Chrome ignores mouse input for the whole of the first browser
# session in a process (see ApplicationSystemTestCase#prime_pointer). Reset the
# session once per process to prime it. Unlike the system suite — where the
# browser persists across tests — cucumber resets the browser between
# scenarios, so the wrapped block (the sign-in) must ALWAYS run: skipping it
# would leave every scenario after the first logged out.
module SystemParity
  class << self
    attr_accessor :pointer_primed
  end

  def prime_pointer
    unless SystemParity.pointer_primed
      SystemParity.pointer_primed = true
      Capybara.reset_sessions!
    end

    yield
  end
end

World(SystemParity)
