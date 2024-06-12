require 'test_helper'

class Authenticate::ByBearerTokenTest < ActionDispatch::IntegrationTest
  test "should auth user with a bearer token and returns proper JSON" do
    get conversation_messages_path(conversations(:greeting), version: 1), headers: bearer_token_for(clients(:keith_api))
    assert_response :success
    data = nil
    assert_nothing_raised do
      data = JSON.parse(response.body)
    end
    refute data.keys.include?("rendered_format")
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

  test "auth fails when an authentication does not exist" do
    client = clients(:rob_browser)
    get conversation_messages_path(conversations(:greeting), version: 1), headers: bearer_token_for(client, "#{client.id}:#{client.token}")
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
