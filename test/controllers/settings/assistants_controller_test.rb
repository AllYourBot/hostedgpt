require "test_helper"

class Settings::AssistantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @assistant = assistants(:samantha)
    @user = @assistant.user
    login_as @user
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

  test "should show error when creating assistant with duplicate slug" do
    existing_assistant = assistants(:samantha)
    params = {
      name: "New Assistant",
      slug: existing_assistant.slug,
      description: "A new description",
      instructions: "New instructions",
      language_model_id: language_models(:gpt_4o).id
    }

    assert_no_difference("Assistant.count") do
      post settings_assistants_url, params: { assistant: params }
    end

    assert_response :unprocessable_content
    assert_contains_text "main", "Slug has already been taken"
  end

  test "should get edit" do
    get edit_settings_assistant_url(@assistant)
    assert_response :success
    assert_contains_text "div#nav-container", "Your Account"
    assert_contains_text "div#nav-container", "New Assistant"
  end

  test "form should display a DELETE button if this is not your last assistant" do
    assert @user.assistants.length > 1, "User needs to have more than one assistant"
    get edit_settings_assistant_url(@assistant)
    assert_response :success
    assert_contains_text "main", "Delete"
  end

  test "form should NOT display a DELETE button if this is your last assistant" do
    @user.assistants.where.not(id: @assistant.id).map(&:destroy!)
    @user.reload
    assert @user.assistants.length == 1, "Test user needs to have more than one assistant"
    get edit_settings_assistant_url(@user.assistants.first)
    assert_response :success
    assert_contains_text "main", "Delete"
  end

  test "should allow language_model selection" do
    get edit_settings_assistant_url(@assistant)
    assert_select "label", "Language model"
    assert_select "select#assistant_language_model_id"
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

  test "should update conversation_starters, DROPPING the fields left blank" do
    params = { conversation_starters: ["What should I cook tonight?", "", "Plan my week", ""] }
    patch settings_assistant_url(@assistant), params: { assistant: params }

    assert_redirected_to edit_settings_assistant_url(@assistant)
    assert_equal ["What should I cook tonight?", "Plan my week"], @assistant.reload.conversation_starters, "Only the filled-in starters should be saved"
  end

  test "should CLEAR conversation_starters when every field is blank" do
    @assistant.update!(conversation_starters: ["What should I cook tonight?"])

    patch settings_assistant_url(@assistant), params: { assistant: { conversation_starters: ["", "", "", ""] } }

    assert_redirected_to edit_settings_assistant_url(@assistant)
    assert_equal [], @assistant.reload.conversation_starters, "Blanking every field should bring back the default suggestions"
  end

  test "should show error when updating conversation_starters with TOO MANY questions" do
    params = { conversation_starters: Array.new(Assistant::MAX_CONVERSATION_STARTERS + 1) { |index| "Question #{index}" } }
    patch settings_assistant_url(@assistant), params: { assistant: params }

    assert_response :unprocessable_content
    assert_contains_text "main", "Conversation starters can have at most #{Assistant::MAX_CONVERSATION_STARTERS} questions"
    assert_equal [], @assistant.reload.conversation_starters, "Nothing should have been saved"
  end

  test "edit should show a field for each conversation starter, filled with the saved ones" do
    @assistant.update!(conversation_starters: ["What should I cook tonight?"])

    get edit_settings_assistant_url(@assistant)
    assert_response :success

    assert_select "input[name=?]", "assistant[conversation_starters][]", { count: Assistant::MAX_CONVERSATION_STARTERS }, "There should be a field for every starter"
    assert_select "input#assistant_conversation_starters_0[value=?]", "What should I cook tonight?", { count: 1 }, "The saved starter should fill the first field"
    assert_select "input#assistant_conversation_starters_1:not([value])", { count: 1 }, "The fields past the saved starters should be empty"
  end

  test "edit should list the context files but NOT the images the assistant generated in its conversations" do
    message = messages(:image_generation_explained)
    GeneratedImage.new(Base64.strict_encode64(file_fixture("cat.png").binread)).attach_to!(message)
    generated_image = message.documents.last
    assert_equal @assistant, generated_image.assistant, "The generated image should record the assistant that made it"

    get edit_settings_assistant_url(@assistant)
    assert_response :success

    assert_select "#context li", { count: 1 }, "Only the uploaded context file should be listed"
    assert_select "#context li#document_#{documents(:background).id}", { count: 1 }, "The uploaded context file should be listed"
    assert_select "#context li#document_#{generated_image.id}", { count: 0 }, "The generated image should not be listed as a context file"
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
