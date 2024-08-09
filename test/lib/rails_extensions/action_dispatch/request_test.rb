require "test_helper"

class ActionDispatch::RequestTest < ActiveSupport::TestCase

  test "operating_system recognizes Windows" do
    request = request_with_agent "Windows Chrome"
    assert_equal "Windows", request.operating_system
  end

  test "operating_system recognizes Macintosh" do
    request = request_with_agent "Macintosh Safari"
    assert_equal "Macintosh", request.operating_system
  end

  test "operating_system recognizes Linux" do
    request = request_with_agent "Linux Firefox"
    assert_equal "Linux", request.operating_system
  end

  test "operating_system recognizes Android" do
    request = request_with_agent "Android Chrome"
    assert_equal "Android", request.operating_system
  end

  test "operating_system recognizes iPhone" do
    request = request_with_agent "iPhone Safari"
    assert_equal "iPhone", request.operating_system
  end

  test "browser recognizes Chrome" do
    request = request_with_agent "Windows Chrome"
    assert_equal "Chrome", request.browser
  end

  test "browser recognizes Safari" do
    request = request_with_agent "Macintosh Safari"
    assert_equal "Safari", request.browser
  end

  test "browser recognizes Firefox" do
    request = request_with_agent "Linux Firefox"
    assert_equal "Firefox", request.browser
  end

  test "browser recognizes Edge" do
    request = request_with_agent "Windows Edge"
    assert_equal "Edge", request.browser
  end

  test "browser recognizes Opera" do
    request = request_with_agent "Windows Opera"
    assert_equal "Opera", request.browser
  end

  private

  def request_with_agent(agent_str)
    ActionDispatch::Request.new("HTTP_USER_AGENT" => agent_str)
  end
end
