require "test_helper"

class AssistantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:keith)
    @assistant = @user.assistants.ordered.first
    login_as @user
  end

  test "index redirects to conversation if assistants_page is disabled" do
    stub_features(assistants_page: false) do
      get assistants_url
    end
    assert_redirected_to new_assistant_message_path(@assistant)
  end

  test "index shows assistants if assistants_page is enabled" do
    stub_features(assistants_page: true) do
      get assistants_url
    end
    assert_response :success
  end

  test "index redirects to conversation on a mobile device even if assistants_page is enabled" do
    stub_features(assistants_page: true) do
      get assistants_url, headers: { "User-Agent" => "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1" }
    end
    assert_redirected_to new_assistant_message_path(@assistant)
  end
end
