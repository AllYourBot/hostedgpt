require "test_helper"

class Assistant::ConversationStartersTest < ActiveSupport::TestCase
  test "conversation_starters defaults to an empty list" do
    assert_equal [], assistants(:samantha).conversation_starters, "An assistant without starters should fall back to the default suggestions"
  end

  test "conversation_starters STRIPS each question and DROPS the blank ones" do
    assistant = assistants(:samantha)
    assistant.update!(conversation_starters: ["  What should I cook tonight? ", "", " ", "Plan my week"])

    assert_equal ["What should I cook tonight?", "Plan my week"], assistant.reload.conversation_starters, "Blank fields from the form should not be saved as starters"
  end

  test "conversation_starters IS valid with up to the maximum number of questions" do
    assistant = assistants(:samantha)
    assistant.conversation_starters = Array.new(Assistant::MAX_CONVERSATION_STARTERS) { |index| "Question #{index}" }

    assert assistant.valid?, "An assistant should accept #{Assistant::MAX_CONVERSATION_STARTERS} starters"
  end

  test "conversation_starters IS NOT valid with more than the maximum number of questions" do
    assistant = assistants(:samantha)
    assistant.conversation_starters = Array.new(Assistant::MAX_CONVERSATION_STARTERS + 1) { |index| "Question #{index}" }

    refute assistant.valid?, "An assistant should not accept more than #{Assistant::MAX_CONVERSATION_STARTERS} starters"
    assert_includes assistant.errors.full_messages, "Conversation starters can have at most #{Assistant::MAX_CONVERSATION_STARTERS} questions",
      "The error should count questions, not characters"
  end
end
