require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get password_resets_new_url
    assert_response :success
  end

  test "should get create" do
    get password_resets_create_url
    assert_response :success
  end

  test "should get edit" do
    get password_resets_edit_url
    assert_response :success
  end

  test "should get update" do
    get password_resets_update_url
    assert_response :success
  end
end
