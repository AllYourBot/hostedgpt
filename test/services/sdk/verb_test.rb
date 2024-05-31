require "test_helper"

class SDK::VerbTest < ActiveSupport::TestCase
  setup do
    @verb = SDK::Verb.new(url: nil)
  end

  test "smart_merge" do
    h1 = {
      url: "old",
      params: {
        content_type: "json",
      },
      status: [ 200 ],
    }

    h2 = {
      url: "new",
      params: {
        content_type: "xml",
        authorization: "bearer",
      },
      status: 401,
    }

    expected = {
      url: "new",
      params: {
        content_type: "xml",
        authorization: "bearer",
      },
      status: [ 200, 401 ],
    }

    assert_equal expected, @verb.send(:smart_merge, h1, h2)

    h2[:status] = [ 401 ]
    expected[:status] = [ 401 ]
    assert_equal expected, @verb.send(:smart_merge, h1, h2)

    h2[:status] = 200
    expected[:status] = [ 200 ]
    assert_equal expected, @verb.send(:smart_merge, h1, h2)
  end
end