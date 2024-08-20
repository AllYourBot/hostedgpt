require "test_helper"

class Settings::LanguageModelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @language_model = language_models(:gpt_best)
    @user = @language_model.user # Keith
    login_as @user
  end

  test "should get index for user" do
    get settings_language_models_url
    assert_response :success
    assert_select "table#language-models tbody tr", count: 18
    assert_select "p a", "Add New"
  end

  test "should get new" do
    get new_settings_language_model_url
    assert_response :success
  end

  test "should create language_model" do
    params = @language_model.slice(:api_name, :api_service_id, :name, :supports_images)
    params[:api_name] = "new service"

    assert_difference("LanguageModel.count") do
      post settings_language_models_url, params: { language_model: params }
    end

    assert_redirected_to settings_language_models_url
    assert_equal "Saved", flash[:notice]
    assert_equal params, LanguageModel.last.slice(:api_name, :api_service_id, :name, :supports_images)
    assert_equal @user, LanguageModel.last.user
  end

  test "should get edit" do
    get edit_settings_language_model_url(@language_model)
    assert_response :success
    assert_contains_text "div#nav-container", "Your Account"
    assert_select "h1", "Editing gpt-best"
    assert_select "form"
  end

  test "create should not have supports_tools checkbox" do
    get new_settings_language_model_url
    assert_response :success
    assert_select "form" do
      assert_select 'input[name="language_model[supports_tools]"]'
      assert_select 'input[name="language_model[supports_tools]"][checked="checked"]', false # Not checked by default, from schema
    end
  end

  test "edit should have supports_tools checkbox checked" do
    get edit_settings_language_model_url(@language_model)
    assert_response :success
    assert_select "form" do
      assert_select 'input[name="language_model[supports_tools]"][checked="checked"]'
    end
  end

  test "edit should have supports_tools checkbox unchecked" do
    get edit_settings_language_model_url(language_models(:guanaco))
    assert_response :success
    assert_select "form" do
      assert_select 'input[name="language_model[supports_tools]"]'
      assert_select 'input[name="language_model[supports_tools]"][checked="checked"]', false
    end
  end

  test "should not allow viewing other user's records" do
    get edit_settings_language_model_url(language_models(:pacos))
    assert_response :see_other
    assert_redirected_to settings_language_models_path
    assert_equal "The Language Model could not be found", flash[:alert]
  end

  test "cannot view a deleted record" do
    @language_model.deleted!
    get edit_settings_language_model_url(@language_model)
    assert_response :see_other
    assert_redirected_to settings_language_models_path
    assert_equal "The Language Model could not be found", flash[:alert]
  end

  test "form should display a DELETE button" do
    get edit_settings_language_model_url(@language_model)
    assert_response :success
    assert_contains_text "main", "Delete"
  end

  test "form should display a DELETE button even if this is your last language model" do
    @user.language_models.each do |record|
      next if record == @language_model
      record.destroy!
    end
    @user.reload
    assert @user.language_models.length == 1, "User needs to have only one language model"
    get edit_settings_language_model_url(@language_model)
    assert_response :success
    assert_contains_text "main", "Delete"
  end

  test "should update supports_tools" do
    assert @language_model.supports_tools?
    patch settings_language_model_url(@language_model), params: { language_model: {supports_tools: false }}
    refute @language_model.reload.supports_tools?

    language_model = language_models(:guanaco)
    refute language_model.supports_tools?
    patch settings_language_model_url(language_model), params: { language_model: {supports_tools: true }}
    assert language_model.reload.supports_tools?
  end

  test "should not update other user's language_model" do
    original_params = language_models(:alpaca).slice(:api_name, :name)
    params = {"api_name": "New Name", "name": "New Desc"}
    patch settings_language_model_url(language_models(:alpaca)), params: { language_model: params }

    assert_redirected_to settings_language_models_url
    assert_equal "The Language Model could not be found", flash[:alert]
    assert_equal original_params, language_models(:alpaca).reload.slice(:api_name, :name)
  end

  test "should update language_model" do
    params = {"api_name" => "New Name", "name" => "New Desc", "supports_images" => true}
    patch settings_language_model_url(@language_model), params: { language_model: params }

    assert_redirected_to settings_language_models_url
    assert_equal "Saved", flash[:notice]
    assert_equal params, @language_model.reload.slice(:api_name, :name, :supports_images)
  end

  test "destroy should soft-delete language_model" do
    assert_no_difference "LanguageModel.count" do
      delete settings_language_model_url(@language_model)
    end

    assert @language_model.reload.deleted?
    assert_redirected_to settings_language_models_url
    assert flash[:notice].present?, "There should have been a success message"
    refute flash[:alert].present?, "There should NOT have been an error message"
  end
end
