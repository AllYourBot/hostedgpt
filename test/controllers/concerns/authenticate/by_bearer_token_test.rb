require 'test_helper'

class Authenticate::ByBearerTokenTest < ActionDispatch::IntegrationTest
  test "should auth user with a bearer token and returns JSON" do
    get conversation_messages_path(conversations(:greeting), version: 1), headers: bearer_token_for(clients(:keith_api))
    assert_response :success
    assert_nothing_raised do
      JSON.parse(response.body)
    end
  end

  test "auth fails when bearer token is missing" do
    get conversation_messages_path(conversations(:greeting), version: 1)
    assert_redirected_to login_path, "Expected this request to fail"
  end

  test "auth fails when bearer token contains just ID" do
    get conversation_messages_path(conversations(:greeting), version: 1), headers: bearer_token_for(clients(:keith_api), clients(:keith_api).id)
    assert_response :unauthorized
  end

  test "auth fails when bearer token contains just TOKEN" do
    get conversation_messages_path(conversations(:greeting), version: 1), headers: bearer_token_for(clients(:keith_api), clients(:keith_api).token)
    assert_response :unauthorized
  end

  private

  def bearer_token_for(client, token = nil)
    {
      "Accept" => "application/json",
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{token || client.bearer_token}",
    }
  end
end
