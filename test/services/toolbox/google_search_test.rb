require "test_helper"

class Toolbox::GoogleSearchTest < ActiveSupport::TestCase
  setup do
    @google_search = Toolbox::GoogleSearch.new
    WebMock.enable!
  end

  test "google_search returns the expected result" do
    expected_result = {
      message_to_user: "Web query: Sandi Metz POODR title",
      query_results: "Practical Object-Oriented Design in Ruby by Sandi Metz"
    }
    body = "<!doctype html><html><body><div class=\"BNeawe vvjwJb AP7Wnd\">#{expected_result[:query_results]}</div></body></html>"

    stub_request(:get, /www.google.com/)
      .with(
        headers: {
          "Accept"=>"*/*",
          "Accept-Encoding"=>"gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "User-Agent"=>"Ruby"
        }
      )
      .to_return(status: 200, body: body, headers: {})

    result = @google_search.google_search(query_s: "Sandi Metz POODR title")
    assert_equal expected_result, result
  end
end
