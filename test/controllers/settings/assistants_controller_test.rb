require "test_helper"

class Settings::AssistantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @assistant = assistants(:samantha)
    login_as @assistant.user
  end

  test "should get new" do
    get new_settings_assistant_url
    assert_response :success
  end

  test "should create assistant" do
    params = assistants(:samantha).slice(:name, :description, :instructions, :language_model_id)

    assert_difference("Assistant.count") do
      post settings_assistants_url, params: { assistant: params }
    end

    assert_redirected_to edit_settings_assistant_url(Assistant.last)
    assert_nil flash[:error]
    assert_equal params, Assistant.last.slice(:name, :description, :instructions, :language_model_id)
  end

  test "should get edit" do
    get edit_settings_assistant_url(@assistant)
    assert_response :success
  end

  test "should update assistant" do
    params = assistants(:samantha).slice(:name, :description, :instructions).transform_values { |value| "#{value}-2" }
    patch settings_assistant_url(@assistant), params: { assistant: params }

    assert_redirected_to edit_settings_assistant_url(@assistant)
    assert_nil flash[:error]
    assert_equal params, @assistant.reload.slice(:name, :description, :instructions)
  end

  test "destroy should soft-delete assistant" do
    assert_difference("Assistant.count", 0) do
      delete settings_assistant_url(@assistant)
    end

    assert @assistant.reload.deleted?
    assert_redirected_to new_settings_assistant_url
  end
end
