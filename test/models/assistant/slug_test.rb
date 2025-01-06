require "test_helper"

class Assistant::SlugTest < ActiveSupport::TestCase
  test "sets a default slug" do
    samantha = assistants(:samantha)
    assert_equal "samantha", samantha.slug

    keith_gpt4 = assistants(:keith_gpt4)
    assert_equal "gpt-4o", keith_gpt4.slug
    keith_gpt4.slug = nil
    keith_gpt4.save!
    assert_equal "openai-gpt-4o", keith_gpt4.slug

    lm = language_models(:gpt_best)
    user = users(:keith)
    same_name1 = user.assistants.create!(language_model: lm, name: "Best OpenAI Model")
    assert_equal "best-openai-model", same_name1.slug
    same_name2 = user.assistants.create!(language_model: lm, name: "Best OpenAI Model")
    assert_equal "best-openai-model--1", same_name2.slug
    same_name3 = user.assistants.create!(language_model: lm, name: "Best OpenAI Model")
    assert_equal "best-openai-model--2", same_name3.slug

    similar_name = user.assistants.create!(language_model: lm, name: "Best OpenAI Model 2")
    assert_equal "best-openai-model-2", similar_name.slug
    similar_name2 = user.assistants.create!(language_model: lm, name: "Best OpenAI Model 2")
    assert_equal "best-openai-model-2--1", similar_name2.slug
  end

  test "ensure all fixtures have a slug defined since it will not be set automatically" do
    Assistant.all.each do |assistant|
      assert_not_nil assistant.slug, "Assistant #{assistant.name} does not have a slug defined in the fixture"
    end
  end

  test "clears slug when assistant is deleted" do
    assistant = assistants(:samantha)
    original_slug = assistant.slug
    assert_not_nil original_slug

    assistant.deleted!
    assert_nil assistant.reload.slug

    # Create a new assistant with the same name
    new_assistant = assistant.user.assistants.create!(
      name: assistant.name,
      language_model: assistant.language_model,
      tools: assistant.tools
    )
    assert_equal original_slug, new_assistant.slug
  end

  test "does not clear slug when other attributes change" do
    assistant = assistants(:samantha)
    original_slug = assistant.slug

    assistant.update!(name: "New Name")
    assert_equal original_slug, assistant.reload.slug
  end
end
