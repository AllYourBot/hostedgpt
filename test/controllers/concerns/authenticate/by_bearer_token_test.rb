require "test_helper"

class Authenticate::ByBearerTokenTest < ActionDispatch::IntegrationTest
  test "simple get request should auth user with a bearer token and returns proper JSON" do
    get conversation_messages_path(conversations(:greeting), version: 1), headers: bearer_token_for(clients(:keith_api))
    assert_response :success
    data = proper_json_response
    refute data.keys.include?("rendered_format")
    refute data.keys.include?("system_ivar")
  end

  test "GET request that redirects should auth user and return a special JSON response for redirect" do
    path_which_will_redirect = conversation_messages_path(conversations(:greeting))
    get path_which_will_redirect, headers: bearer_token_for(clients(:keith_api))
    assert_response :success
    data = proper_json_response

    assert_nil data["notice"]
    assert_equal "see_other", data["status"]
    assert_equal conversation_messages_path(conversations(:greeting), version: 1), data["redirect_to"]
  end

  test "POST request that redirects should auth user and return a special JSON response for redirect" do
    params = assistants(:samantha).slice(:name, :description, :instructions, :language_model_id)

    post settings_assistants_url, headers: bearer_token_for(clients(:keith_api)), params: { assistant: params }.to_json
    assert_response :success
    data = proper_json_response

    assert_equal "Saved", data["notice"]
    assert_equal "see_other", data["status"]
    assert_equal edit_settings_assistant_path(Assistant.last), data["redirect_to"]
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

  def proper_json_response
    data = nil
    assert_nothing_raised do
      data = JSON.parse(response.body)
    end
    data
  end
end
