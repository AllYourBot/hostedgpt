require "test_helper"

class Toolbox::ImageTest < ActiveSupport::TestCase
  setup do
    @tool = Toolbox::Image.new
    @prompt = "A cartoon image of a cat"
  end

  test "generate_an_image asks the current backend and composes the payload" do
    Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
      AIBackend::OpenAI.stub :generate_image, { b64_json: "BASE64_IMAGE_DATA", model: "gpt-image-1", provider: "OpenAI" } do
        result = @tool.generate_an_image(image_generation_prompt_s: @prompt)

        assert_equal @prompt, result[:prompt_given]
        assert_equal "BASE64_IMAGE_DATA", result[:json_of_generated_image]
        assert_includes result[:note_to_assistant], "image"
        assert_equal "Image created by tool using OpenAI model gpt-image-1", result[:message_to_user]
      end
    end
  end

  test "flag off: dispatch routes through ai_backend to the SDK backend" do
    stub_features(use_ruby_llm: false) do
      Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
        received = nil
        AIBackend::OpenAI.stub :generate_image, ->(prompt:, user:) {
          received = { called: true }
          { b64_json: "BASE64_IMAGE_DATA", model: "gpt-image-1", provider: "OpenAI" }
        } do
          result = @tool.generate_an_image(image_generation_prompt_s: @prompt)

          assert received[:called]
          assert_equal "BASE64_IMAGE_DATA", result[:json_of_generated_image]
          assert_equal "Image created by tool using OpenAI model gpt-image-1", result[:message_to_user]
        end
      end
    end
  end

  test "the provider label follows the backend that actually generated the image" do
    Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
      AIBackend::OpenAI.stub :generate_image, { b64_json: "BASE64_IMAGE_DATA", model: "acme-image-2", provider: "Acme" } do
        result = @tool.generate_an_image(image_generation_prompt_s: @prompt)

        assert_equal "Image created by tool using Acme model acme-image-2", result[:message_to_user]
      end
    end
  end

  test "generate_an_image works with an Anthropic assistant by delegating through its backend to OpenAI" do
    anthropic_message = messages(:image_generation_tool_call).dup
    anthropic_message.assistant = assistants(:keith_claude3)

    Current.set(user: users(:keith), message: anthropic_message) do
      openai_received = nil
      AIBackend::OpenAI.stub :generate_image, ->(prompt:, user:) {
        openai_received = { prompt: prompt, user: user }
        { b64_json: "BASE64_IMAGE_DATA_ANTHROPIC", model: "gpt-image-1", provider: "OpenAI" }
      } do
        result = @tool.generate_an_image(image_generation_prompt_s: @prompt)

        assert_equal @prompt, openai_received[:prompt]
        assert_equal users(:keith), openai_received[:user]
        assert_equal "BASE64_IMAGE_DATA_ANTHROPIC", result[:json_of_generated_image]
      end
    end
  end

  test "generate_an_image appends the current assistant context to the backend key error" do
    users(:keith).api_services.update_all(deleted_at: Time.current) # rubocop:disable Rails/SkipsModelValidations

    Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
      error = assert_raises(RuntimeError) { @tool.generate_an_image(image_generation_prompt_s: @prompt) }
      expected_backend = messages(:image_generation_tool_call).assistant.language_model.api_service.name
      assert_includes error.message, "OpenAI API key not found"
      assert_includes error.message, "to use image generation with #{expected_backend}."
    end
  end
end
