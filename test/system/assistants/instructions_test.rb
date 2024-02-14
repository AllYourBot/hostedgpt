require "application_system_test_case"

class AssistantsInstructionsTest < ApplicationSystemTestCase
  setup do
    @assistant = assistants(:samantha)
  end

  test "should update Assistant" do
    login_as @assistant.user
    visit assistant_instructions_url(@assistant)

    fill_in "assistant[instructions]", with: "Updated Instructions"
    click_text "Update"

    assert_text "Instructions have been saved."
  end
end
