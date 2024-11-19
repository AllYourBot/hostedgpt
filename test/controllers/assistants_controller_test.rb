require "test_helper"

class AssistantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:keith)
    @assistant = @user.assistants.ordered.first
    login_as @user
  end

  test "index shows assistants" do
    get assistants_url
    assert_response :success
  end
end
