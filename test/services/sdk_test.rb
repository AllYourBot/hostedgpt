require "test_helper"

class SDKTest < ActiveSupport::TestCase
  class Service < SDK
  end

  class HeaderService < SDK
    def header
      { "Content-Type": "text/plain", Type: "test" }
    end
  end

  class BearerService < SDK
    def bearer_token
      "abc123"
    end
  end

  class HeaderBearerService < SDK
    def header
      { "Content-Type": "text/plain", Type: "test" }
    end

    def bearer_token
      "abc123"
    end
  end

  class StatusService < SDK
    def expected_status
      301
    end
  end

  setup do
    @service_get = Service.new.get("http://dummy")
    @service_post = Service.new.post("http://dummy")

    @header_service_get = HeaderService.new.get("http://dummy")
    @header_service_post = HeaderService.new.post("http://dummy")

    @bearer_service_get = BearerService.new.get("http://dummy")
    @bearer_service_post = BearerService.new.post("http://dummy")

    @header_bearer_service_get = HeaderBearerService.new.get("http://dummy")
    @header_bearer_service_post = HeaderBearerService.new.post("http://dummy")

    @status_service_get = StatusService.new.get("http://dummy")
    @status_service_post = StatusService.new.post("http://dummy")
  end

  test "default headers are present" do
    headers = { "Content-Type": "text/plain", Type: "test" }
    assert_equal headers, @header_service_get.instance_variable_get(:@headers)
    assert_equal headers, @header_service_post.instance_variable_get(:@headers)
  end

  test "default headers can be appended with additional headers" do
    headers = { "Content-Type": "text/plain", Type: "test", Cache: true }
    assert_equal headers, @header_service_get.header(Cache: true).instance_variable_get(:@headers)
    assert_equal headers, @header_service_post.header(Cache: true).instance_variable_get(:@headers)
  end

  test "headers can be added with no defaults" do
    headers = { Cache: true }
    assert_equal headers, @service_get.header(Cache: true).instance_variable_get(:@headers)
    assert_equal headers, @service_post.header(Cache: true).instance_variable_get(:@headers)
  end

  test "json_content can be used with default headers and overrides" do
    headers = { "Content-Type": "application/json", Type: "test" }
    assert_equal headers, @header_service_get.json_content.instance_variable_get(:@headers)
    assert_equal headers, @header_service_post.json_content.instance_variable_get(:@headers)
  end

  test "json_content can be used with no defaults" do
    headers = { "Content-Type": "application/json" }
    assert_equal headers, @service_get.json_content.instance_variable_get(:@headers)
    assert_equal headers, @service_post.json_content.instance_variable_get(:@headers)
  end

  test "www_content can be used with default headers and overrides" do
    headers = { "Content-Type": "application/x-www-form-urlencoded", Type: "test" }
    assert_equal headers, @header_service_get.www_content.instance_variable_get(:@headers)
    assert_equal headers, @header_service_post.www_content.instance_variable_get(:@headers)
  end

  test "www_content can be used with no defaults" do
    headers = { "Content-Type": "application/x-www-form-urlencoded" }
    assert_equal headers, @service_get.www_content.instance_variable_get(:@headers)
    assert_equal headers, @service_post.www_content.instance_variable_get(:@headers)
  end

  test "default bearer_token gets added as a header" do
    assert_equal "Bearer abc123", @bearer_service_get.instance_variable_get(:@headers)[:Authorization]
    assert_equal "Bearer abc123", @bearer_service_post.instance_variable_get(:@headers)[:Authorization]
  end

  test "default bearer_token can be overriden by a future header" do
    assert_equal "new", @bearer_service_get.header(Authorization: "new").instance_variable_get(:@headers)[:Authorization]
    assert_equal "new", @bearer_service_post.header(Authorization: "new").instance_variable_get(:@headers)[:Authorization]
  end

  test "default bearer_token works with default headers" do
    headers = { "Content-Type": "text/plain", Type: "test", Authorization: "Bearer abc123" }
    assert_equal headers, @header_bearer_service_get.instance_variable_get(:@headers)
    assert_equal headers, @header_bearer_service_post.instance_variable_get(:@headers)
  end

  test "expected_status defaults to 200 with no defaults" do
    assert_equal [200], @service_get.instance_variable_get(:@expected_statuses)
    assert_equal [200], @service_post.instance_variable_get(:@expected_statuses)
  end

  test "expected_status can be appended without arrays" do
    assert_equal [200, 400], @service_get.expected_status(400).instance_variable_get(:@expected_statuses)
    assert_equal [200, 400], @service_post.expected_status(400).instance_variable_get(:@expected_statuses)
  end

  test "expected_status can be overriden with a new array" do
    assert_equal [400], @service_get.expected_status([400]).instance_variable_get(:@expected_statuses)
    assert_equal [400], @service_post.expected_status([400]).instance_variable_get(:@expected_statuses)
  end

  test "expected_status starts with the default" do
    assert_equal [301], @status_service_get.instance_variable_get(:@expected_statuses)
    assert_equal [301], @status_service_post.instance_variable_get(:@expected_statuses)
  end
end
