require "test_helper"

class Settings::LanguageModelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @language_model = language_models(:camel)
    @user = @language_model.user # Keith
    login_as @user
  end

  test "should get index for keith user" do
    get settings_language_models_url
    assert_response :success
    assert_select "table#language-models tbody tr", count: 26
    assert_select "p a", "Add New"
  end

  test "should get index for rob user" do
    get logout_path
    login_as users(:rob)
    get settings_language_models_url
    assert_select "table#language-models tbody tr", count: 24
  end

  test "should get new" do
    get new_settings_language_model_url
    assert_response :success
  end

  test "should create language_model" do
    params = language_models(:camel).slice(:api_name, :api_service_id, :description, :supports_images)
    params[:api_name] = "new service"

    assert_difference("LanguageModel.count") do
      post settings_language_models_url, params: { language_model: params }
    end

    assert_redirected_to settings_language_models_url
    assert_nil flash[:error]
    assert_equal params, LanguageModel.last.slice(:api_name, :api_service_id, :description, :supports_images)
    assert_equal @user, LanguageModel.last.user
  end

  test "should get edit" do
    get edit_settings_language_model_url(@language_model)
    assert_response :success
    assert_contains_text "div#nav-container", "Your Account"
    assert_select "h1", "Editing  Language Model camel"
    assert_select "form"
  end

  test "cannot view a deleted record" do
    @language_model.destroy!
    get edit_settings_language_model_url(@language_model)
    assert_response :see_other
    assert_redirected_to new_settings_language_model_url
    assert_equal "The Language Model could not be found", flash[:notice]
  end

  test "form should display a DELETE button" do
    get edit_settings_language_model_url(@language_model)
    assert_response :success
    assert_contains_text "main", "Delete"
  end

  test "form should display a DELETE button even if this is your last language model" do
    language_models(:guanaco).destroy!
    assert @user.language_models.length == 1, "User needs to have only one language model"
    get edit_settings_language_model_url(@language_model)
    assert_response :success
    assert_contains_text "main", "Delete"
  end

  test "should not update other user's language_model" do
    original_params = language_models(:alpaca).slice(:api_name, :description)
    params = {"api_name": "New Name", "description": "New Desc"}
    patch settings_language_model_url(language_models(:alpaca)), params: { language_model: params }

    assert_redirected_to new_settings_language_model_url
    assert_nil flash[:error]
    assert_equal "The Language Model could not be found", flash[:notice]
    assert_equal original_params, language_models(:alpaca).reload.slice(:api_name, :description)
  end

  test "should update language_model" do
    params = {"api_name" => "New Name", "description" => "New Desc", "supports_images" => true}
    patch settings_language_model_url(@language_model), params: { language_model: params }

    assert_redirected_to edit_settings_language_model_url(@language_model)
    assert_nil flash[:error]
    assert_equal params, @language_model.reload.slice(:api_name, :description, :supports_images)
  end

  test "destroy should soft-delete language_model" do
    assert_difference "LanguageModel.count", 0 do
      delete settings_language_model_url(@language_model)
    end

    assert @language_model.reload.deleted?
    assert_redirected_to new_settings_language_model_url
    assert flash[:notice].present?, "There should have been a success message"
    refute flash[:alert].present?, "There should NOT have been an error message"
  end

end
