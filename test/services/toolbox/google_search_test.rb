require "test_helper"

class Toolbox::GoogleSearchTest < ActiveSupport::TestCase
  setup do
    @google_search = Toolbox::GoogleSearch.new
  end

  test "google_search does request and doesn't fail" do
    allow_request(:get, :google_search) do
      result = @google_search.google_search(query_s: "Sandi Metz POODR title")
      assert result.values.all? { |value| value.present? }
    end
  end

  test "google_search returns the expected result" do
    # TODO: fix this.  should I be using webmock for this?
    expected_result = {
      message_to_user: "Web query: Sandi Metz POODR title",
      query_results: "Practical Object-Oriented Design in Ruby by Sandi Metz"
    }
    body = "<!doctype html><html><body><div class=\"BNeawe vvjwJb AP7Wnd\">#{expected_result[:query_results]}</div></body></html>"

    stub_request(:get, "https://www.google.com/search?q=Sandi%20Metz%20POODR%20title")
      .with(
        headers: {
	        'Accept'=>'*/*',
	        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
	        'User-Agent'=>'Ruby'
        }
      )
      .to_return(status: 200, body: body, headers: {})

    result = @google_search.google_search(query_s: "Sandi Metz POODR title")
    assert_equal expected_result, result
  end
end
