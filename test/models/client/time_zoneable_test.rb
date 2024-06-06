require "test_helper"

class Client::TimeZoneableTest < ActiveSupport::TestCase
  test "utc_offset returns nil when no value" do
    assert_nil clients(:keith_api).utc_offset
  end

  test "utc_offset returns proper positive offset" do
    assert_equal "+05:30", clients(:keith_desktop_browser).utc_offset
  end

  test "utc_offset returns proper negative offset" do
    assert_equal "-05:00", clients(:keith_phone_browser).utc_offset
  end
end
