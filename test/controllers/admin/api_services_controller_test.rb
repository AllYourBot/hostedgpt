require "test_helper"

class Admin::APIServicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:keith)
    @api_service = api_services(:rob_openai_service)
  end

  test "should get index listing every user's api services" do
    login_as @admin
    get admin_api_services_url
    assert_response :success
    assert_select "#api-services tbody tr", APIService.not_deleted.count, "Every user's API services should be listed"
    assert_contains_text "##{dom_id(@api_service)} [data-role=owner]", "Rob"
    assert_contains_text "##{dom_id(api_services(:taylor_anthropic_service))} [data-role=owner]", "Taylor"
    assert_select "a[href=?]", edit_admin_api_service_path(@api_service), 1, "Each API service should have an edit link"
    assert_no_match @api_service.token, response.body, "No API key should be shown"
  end

  test "should highlight the Admin menu item and the API Services tab" do
    login_as @admin
    get admin_api_services_url
    assert_select "#menu .bg-gray-200 a[href=?]", admin_users_path, 1, "The Admin menu item should be selected"
    assert_select "#menu .bg-gray-200 a[href=?]", settings_api_services_path, 0, "The settings API Services item should not be selected"
    assert_select "#admin-tabs a[aria-current=page][href=?]", admin_api_services_path, 1, "The API Services tab should be current"
  end

  test "should return not acceptable for a JSON request so no API key leaks" do
    login_as @admin
    get admin_api_services_url(format: :json)
    assert_response :not_acceptable
    assert_no_match @api_service.token, response.body, "No API key should be returned"

    get edit_admin_api_service_url(@api_service, format: :json)
    assert_response :not_acceptable
  end

  test "should return not found for index when user IS NOT an admin" do
    login_as users(:rob)
    get admin_api_services_url
    assert_response :not_found
  end

  test "should get new api service with an owner picker listing every user" do
    login_as @admin
    get new_admin_api_service_url
    assert_response :success
    assert_select "form[action=?][method=post]", admin_api_services_path
    assert_select "select[name=?] option", "api_service[user_id]", User.count, "Every user should be offered as the owner"
  end

  test "should create api service for another user" do
    login_as @admin
    assert_difference "APIService.count", 1 do
      post admin_api_services_url, params: { api_service: {
        user_id: users(:taylor).id, name: "Local LLM", url: "http://localhost:1234/v1/", driver: "openai",
        service_type: "AI", token: "taylor-key"
      } }
    end

    assert_redirected_to admin_api_services_url
    assert flash[:notice].present?, "There should be a flash notice"
    api_service = APIService.last
    assert_equal users(:taylor), api_service.user, "The service should belong to the chosen owner"
    assert_equal "Local LLM", api_service.name, "The name should be saved"
    assert_equal "http://localhost:1234/v1/", api_service.url, "The url should be saved"
    assert_equal "taylor-key", api_service.token, "The key should be saved"
  end

  test "should render new with errors when create IS INVALID" do
    login_as @admin
    assert_no_difference "APIService.count" do
      post admin_api_services_url, params: { api_service: { user_id: users(:taylor).id, name: "", url: "", driver: "openai", service_type: "AI" } }
    end

    assert_response :unprocessable_content
    assert_select "#error_explanation", 1, "The errors should be shown"
    assert_select "select[name=?]", "api_service[user_id]", 1, "The owner picker should be shown again"
  end

  test "should return not found for create when user IS NOT an admin" do
    login_as users(:rob)
    assert_no_difference "APIService.count" do
      post admin_api_services_url, params: { api_service: { user_id: users(:rob).id, name: "X", url: "https://x.com/", driver: "openai", service_type: "AI" } }
    end
    assert_response :not_found
  end

  test "should edit api service WITHOUT revealing its key" do
    login_as @admin
    get edit_admin_api_service_url(@api_service)
    assert_response :success
    assert_contains_text "#owner", "rob@hostedgpt.com"
    assert_select "input[name=?][value=?]", "api_service[name]", @api_service.name
    assert_select "input[name=?]:not([value])", "api_service[token]", 1, "The key field should be empty"
    assert_select "input[name=?][placeholder*=?]", "api_service[token]", "A key is set"
    assert_no_match @api_service.token, response.body, "The key should not be shown"
  end

  test "should update api service" do
    login_as @admin
    patch admin_api_service_url(@api_service), params: { api_service: {
      name: "Rob's OpenAI", url: "https://example.com/v1/", driver: "openai", service_type: "Other", token: "new-key"
    } }

    assert_redirected_to admin_api_services_url
    assert flash[:notice].present?, "There should be a flash notice"
    @api_service.reload
    assert_equal "Rob's OpenAI", @api_service.name, "The name should be updated"
    assert_equal "https://example.com/v1/", @api_service.url, "The url should be updated"
    assert_equal "Other", @api_service.service_type, "The service type should be updated"
    assert_equal "new-key", @api_service.token, "The key should be updated"
    assert_equal users(:rob), @api_service.user, "The owner should be unchanged"
  end

  test "should update api service and KEEP the key when the key field IS BLANK" do
    login_as @admin
    original_token = @api_service.token
    patch admin_api_service_url(@api_service), params: { api_service: { name: "Renamed", token: "" } }

    assert_redirected_to admin_api_services_url
    assert_equal "Renamed", @api_service.reload.name, "The name should be updated"
    assert_equal original_token, @api_service.token, "The key should be unchanged"
  end

  test "should render edit with errors when update IS INVALID" do
    login_as @admin
    patch admin_api_service_url(@api_service), params: { api_service: { name: "" } }

    assert_response :unprocessable_content
    assert_select "#error_explanation", 1, "The errors should be shown"
    assert_equal "OpenAI", @api_service.reload.name, "The name should be unchanged"
  end

  test "should return not found for update when user IS NOT an admin" do
    login_as users(:rob)
    patch admin_api_service_url(api_services(:keith_openai_service)), params: { api_service: { name: "Hacked" } }

    assert_response :not_found
    assert_equal "OpenAI", api_services(:keith_openai_service).reload.name, "The API service should be untouched"
  end

  test "should show a delete button on edit" do
    login_as @admin
    get edit_admin_api_service_url(@api_service)
    assert_select "form[action=?] input[name=_method][value=delete]", admin_api_service_path(@api_service), 1, "There should be a delete button"
  end

  test "should soft delete api service and its language models" do
    login_as @admin
    assert @api_service.language_models.any?, "The service should have language models"

    delete admin_api_service_url(@api_service)

    assert_redirected_to admin_api_services_url
    assert flash[:notice].present?, "There should be a flash notice"
    assert @api_service.reload.deleted_at.present?, "The API service should be soft deleted"
    assert @api_service.language_models.none?, "Its language models should be soft deleted"
  end

  test "should return not found for destroy when user IS NOT an admin" do
    login_as users(:rob)
    delete admin_api_service_url(api_services(:keith_openai_service))

    assert_response :not_found
    assert_nil api_services(:keith_openai_service).reload.deleted_at, "The API service should be untouched"
  end
end
