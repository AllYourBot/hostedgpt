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

  test "should not hide assistants" do
    user = @assistant.user
    5.times do |x|
      user.assistants.create! name: "New assistant #{x+1}", language_model: LanguageModel.find_by(name: 'gpt-3.5-turbo')
    end
    get edit_settings_assistant_url(@assistant)
    assert user.assistants.length > 6
    user.assistants.each do |assistant|
      assert_select %{div[data-role="assistant"] a[data-role="name"] span}, assistant.name
      assert_select %{div.hidden[data-role="assistant"] a[data-role="name"] span}, false
    end
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
    assert_difference("Assistant.count", 0) do
      delete settings_assistant_url(@assistant)
    end

    assert @assistant.reload.deleted?
    assert_redirected_to new_settings_assistant_url
  end
end
