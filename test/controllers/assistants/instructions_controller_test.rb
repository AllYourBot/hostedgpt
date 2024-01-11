require "test_helper"

class Assistants::InstructionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @assistant = assistants(:samantha)
    login_as assistants(:samantha).user
  end

  test "it shows the instructions" do
    get assistant_instructions_url(@assistant)
    assert_response :success
  end

  test "it updates the instructions" do
    new_instructions = "New instructions"
    patch assistant_instructions_url(@assistant), params: {assistant: {instructions: new_instructions }}
    assert_redirected_to assistant_url(@assistant)

    @assistant.reload
    assert_equal new_instructions, @assistant.instructions
  end
end
