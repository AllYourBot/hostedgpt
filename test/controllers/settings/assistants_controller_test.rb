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
    assert_select 'section#menu a[href="/settings/person/edit"] span', "Your Account"
    assert_select 'section#menu a[href="/settings/assistants/new"] span', "New Assistant"
  end

  test "should allow language_model selection" do
    get edit_settings_assistant_url(@assistant)
    assert_select 'label', 'Language model'
    assert_select 'select#assistant_language_model_id'
  end

  test "should update language_model" do
    params = {language_model_id: language_models(:claude_best).id}
    patch settings_assistant_url(@assistant), params: { assistant: params }
    assert_equal language_models(:claude_best), @assistant.reload.language_model
  end

  test "should update assistant" do
    params = assistants(:samantha).slice(:name, :description, :instructions).transform_values { |value| "#{value}-2" }
    patch settings_assistant_url(@assistant), params: { assistant: params }

    assert_redirected_to edit_settings_assistant_url(@assistant)
    assert_nil flash[:error]
    assert_equal params, @assistant.reload.slice(:name, :description, :instructions)
  end

  test "destroy should soft-delete assistant" do
    assert_difference "Assistant.count", 0 do
      delete settings_assistant_url(@assistant)
    end

    assert @assistant.reload.deleted?
    assert_redirected_to new_settings_assistant_url
    assert flash[:notice].present?, "There should have been a success message"
    refute flash[:alert].present?, "There should NOT have been an error message"
  end

  test "destroy on the last assistant should not delete it" do
    user = @assistant.user
    user.assistants.where.not(id: @assistant.id).map(&:destroy)

    assert_no_difference "Assistant.count" do
      delete settings_assistant_url(@assistant)
    end

    refute @assistant.reload.deleted?
    assert_redirected_to new_settings_assistant_url
    refute flash[:notice].present?, "There should NOT have been a success message"
    assert flash[:alert].present?, "There should have been an error message"
  end
end
