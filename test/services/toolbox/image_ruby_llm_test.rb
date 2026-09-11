require "test_helper"

class Toolbox::ImageRubyLLMTest < ActiveSupport::TestCase
  setup do
    @tool = Toolbox::Image.new
    @prompt = "A cartoon image of a cat"
  end

  teardown do
    TestClient::RubyLLM::ContextDouble.reset_recordings!
  end

  test "flag on: generate_an_image paints through RubyLLM with the user's OpenAI key" do
    stub_features(use_ruby_llm: true) do
      Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
        result = @tool.generate_an_image(image_generation_prompt_s: @prompt)

        recorded = TestClient::RubyLLM::ContextDouble.last_paint_call
        assert_equal @prompt, recorded[:prompt]
        assert_equal "abc-secret", recorded[:openai_api_key]
        assert_equal "gpt-image-1", recorded[:kwargs][:model]
        assert_equal :openai, recorded[:kwargs][:provider]
        assert_equal "1024x1024", recorded[:kwargs][:size]

        assert_equal @prompt, result[:prompt_given]
        assert_equal "RUBYLLM_BASE64_IMAGE_DATA", result[:json_of_generated_image]
        assert_includes result[:note_to_assistant], "image"
        assert_equal "Image created by tool using OpenAI model gpt-image-1", result[:message_to_user]
      end
    end
  end

  test "flag on: an Anthropic assistant still generates the image through the user's OpenAI service" do
    stub_features(use_ruby_llm: true) do
      anthropic_message = messages(:image_generation_tool_call).dup
      anthropic_message.assistant = assistants(:keith_claude3)

      Current.set(user: users(:keith), message: anthropic_message) do
        result = @tool.generate_an_image(image_generation_prompt_s: @prompt)

        assert_equal "RUBYLLM_BASE64_IMAGE_DATA", result[:json_of_generated_image]
        assert_equal "Image created by tool using OpenAI model gpt-image-1", result[:message_to_user]
      end
    end
  end

  test "flag on: a Groq service (also driver openai) is not mistaken for the OpenAI image service" do
    stub_features(use_ruby_llm: true) do
      users(:keith).api_services.where(name: "OpenAI").update_all(deleted_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      users(:keith).reload # drop the memoized api_services association so soft-deletes are visible

      Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
        error = assert_raises(RuntimeError) { @tool.generate_an_image(image_generation_prompt_s: @prompt) }
        assert_includes error.message, "OpenAI API key not found"
      end
    end
  end

  test "flag on: generate_an_image raises when the OpenAI service exists but has no token" do
    stub_features(use_ruby_llm: true, default_llm_keys: false) do
      api_services(:keith_openai_service).update!(token: nil)

      Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
        error = assert_raises(RuntimeError) { @tool.generate_an_image(image_generation_prompt_s: @prompt) }
        assert_includes error.message, "OpenAI API key not found"
      end
    end
  end

  test "flag on: generate_an_image surfaces the backend error when no OpenAI service is configured" do
    stub_features(use_ruby_llm: true) do
      users(:keith).api_services.update_all(deleted_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      users(:keith).reload # drop the memoized api_services association so soft-deletes are visible

      Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
        error = assert_raises(RuntimeError) { @tool.generate_an_image(image_generation_prompt_s: @prompt) }
        assert_includes error.message, "OpenAI API key not found"
      end
    end
  end
end
