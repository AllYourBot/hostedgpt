require "test_helper"

class Settings::APIServicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_service = api_services(:keith_service)
    @user = @api_service.user
    login_as @user
  end

  test "should get index" do
    get settings_api_services_url
    assert_response :success
    assert_select "table#api-services tbody tr", count: 1
    assert_select "p a", "Add New"
    assert_select "p#no-api-services", false
  end

  test "should get index without table if user has none" do
    @api_service.destroy!
    get settings_api_services_url
    assert_response :success
    assert_select 'table', count: 0
    assert_select "p a", "Add New"
    assert_select "p#no-api-services", "You have no API services configured."
  end

  test "should get new" do
    get new_settings_api_service_url
    assert_response :success
  end

  test "should create api_service" do
    params = api_services(:keith_service).slice(:url, :driver)
    params[:name] = "new service"

    assert_difference("APIService.count") do
      post settings_api_services_url, params: { api_service: params }
    end

    assert_redirected_to settings_api_services_url
    assert_nil flash[:error]
    assert_equal params, APIService.last.slice(:url, :driver, :name)
    assert_equal @user, APIService.last.user
  end

  test "cannot view a deleted record" do
    @api_service.destroy!
    get edit_settings_api_service_url(@api_service)
    assert_response :see_other
    assert_redirected_to new_settings_api_service_url
    assert_equal "The API Service could not be found", flash[:notice]
  end

  test "should get edit" do
    get edit_settings_api_service_url(@api_service)
    assert_response :success
    assert_contains_text "div#nav-container", "Your Account"
    assert_select "h1", "Editing  API Service Keith Server"
    assert_select "form"
  end

  test "form should display a DELETE button" do
    get edit_settings_api_service_url(@api_service)
    assert_response :success
    assert_contains_text "main", "Delete"
  end

  test "form should  display a DELETE button even if this is your last API service" do
    assert @user.api_services.length == 1, "User needs to have only one API service"
    get edit_settings_api_service_url(@api_service)
    assert_response :success
    assert_contains_text "main", "Delete"
  end

  test "should not update other user's api_service" do
    original_params = api_services(:rob_service).slice(:name, :url)
    params = {"name": "New Name", "url": "http://new-url.com"}
    patch settings_api_service_url(api_services(:rob_service)), params: { api_service: params }

    assert_redirected_to new_settings_api_service_url
    assert_nil flash[:error]
    assert_equal "The API Service could not be found", flash[:notice]
    assert_equal original_params, api_services(:rob_service).reload.slice(:name, :url)
  end

  test "should update api_service" do
    params = {"name" => "New Name", "url" => "http://new-url.com", "token" => "new secret token"}
    patch settings_api_service_url(@api_service), params: { api_service: params }

    assert_redirected_to edit_settings_api_service_url(@api_service)
    assert_nil flash[:error]
    assert_equal params, @api_service.reload.slice(:name, :url, :token)
  end

  test "destroy should soft-delete api_service" do
    assert_difference "APIService.count", 0 do
      delete settings_api_service_url(@api_service)
    end

    assert @api_service.reload.deleted?
    assert_redirected_to new_settings_api_service_url
    assert flash[:notice].present?, "There should have been a success message"
    refute flash[:alert].present?, "There should NOT have been an error message"
  end

end
