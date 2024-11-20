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
end
