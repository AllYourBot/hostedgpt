require "application_system_test_case"

class AssistantsTest < ApplicationSystemTestCase
  setup do
    @assistant = assistants(:samantha)
  end

  test "visiting the index" do
    visit assistants_url
    assert_selector "h1", text: "Assistants"
  end

  test "should create assistant" do
    visit assistants_url
    click_on "New assistant"

    fill_in "Description", with: @assistant.description
    fill_in "Instructions", with: @assistant.instructions
    fill_in "Model", with: @assistant.model
    fill_in "Name", with: @assistant.name
    fill_in "User", with: @assistant.user_id
    click_on "Create Assistant"

    assert_text "Assistant was successfully created"
    click_on "Back"
  end

  test "should update Assistant" do
    visit assistant_url(@assistant)
    click_on "Edit this assistant", match: :first

    fill_in "Description", with: @assistant.description
    fill_in "Instructions", with: @assistant.instructions
    fill_in "Model", with: @assistant.model
    fill_in "Name", with: @assistant.name
    fill_in "User", with: @assistant.user_id
    click_on "Update Assistant"

    assert_text "Assistant was successfully updated"
    click_on "Back"
  end

  test "should destroy Assistant" do
    visit assistant_url(@assistant)
    click_on "Destroy this assistant", match: :first

    assert_text "Assistant was successfully destroyed"
  end
end
