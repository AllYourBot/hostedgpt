require "test_helper"

class AssistantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:keith)
    @assistant = @user.assistants.ordered.first
    login_as @user
  end

  test "should get index" do
    get assistants_url
    assert_redirected_to new_assistant_message_path(@assistant)
  end
end
