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

  test "keeps slug when assistant is deleted" do
    assistant = assistants(:samantha)
    original_slug = assistant.slug
    assert_not_nil original_slug

    assistant.deleted!
    assert_equal original_slug, assistant.reload.slug
  end

  test "clears slug of deleted assistant when new assistant takes its slug" do
    assistant = assistants(:samantha)
    original_slug = assistant.slug
    assistant.deleted!
    assert_equal original_slug, assistant.reload.slug

    # Create a new assistant with the same slug
    new_assistant = assistant.user.assistants.create!(
      name: assistant.name,
      slug: original_slug,
      language_model: assistant.language_model,
      tools: assistant.tools
    )
    assert_equal original_slug, new_assistant.slug
    assert_nil assistant.reload.slug
  end

  test "clears slug of deleted assistant when existing assistant changes to its slug" do
    deleted_assistant = assistants(:samantha)
    original_slug = deleted_assistant.slug
    deleted_assistant.deleted!

    existing_assistant = assistants(:keith_gpt4)
    existing_assistant.update!(slug: original_slug)

    assert_equal original_slug, existing_assistant.reload.slug
    assert_nil deleted_assistant.reload.slug
  end

  test "does not clear slug when other attributes change" do
    assistant = assistants(:samantha)
    original_slug = assistant.slug

    assistant.update!(name: "New Name")
    assert_equal original_slug, assistant.reload.slug
  end

  test "fails to create a new assistant when slug collides with an existing assistant" do
    existing = assistants(:samantha)
    new_assistant = existing.user.assistants.new(
      name: "Different Name",
      slug: existing.slug,
      language_model: existing.language_model
    )
    assert_not new_assistant.valid?
    assert_includes new_assistant.errors[:slug], "has already been taken"
  end

  test "fails to update an assistant's slug when it collides with an existing assistant" do
    existing = assistants(:samantha)
    other = assistants(:keith_gpt4)
    assert_not other.update(slug: existing.slug)
    assert_includes other.errors[:slug], "has already been taken"
  end
end
