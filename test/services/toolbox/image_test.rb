require "test_helper"

class Toolbox::ImageTest < ActiveSupport::TestCase
  setup do
    @tool = Toolbox::Image.new
    @prompt = "A cartoon image of a cat"
  end

  test "generate_an_image calls RubyLLM.paint with expected params and returns payload" do
    image_double = Struct.new(:data, :b64_json).new("BASE64_IMAGE_DATA", nil)

    mock_ctx = Object.new
    mock_ctx.define_singleton_method(:paint) { |*args| image_double }

    Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
      Toolbox::Image.stub :build_llm_context, mock_ctx do
        result = @tool.generate_an_image(image_generation_prompt_s: @prompt)

        assert_equal @prompt, result[:prompt_given]
        assert_equal "BASE64_IMAGE_DATA", result[:json_of_generated_image]
        assert_includes result[:note_to_assistant], "image"
      end
    end
  end

  test "generate_an_image works with Anthropic backend by using OpenAI key" do
    image_double = Struct.new(:data, :b64_json).new("BASE64_IMAGE_DATA_ANTHROPIC", nil)

    mock_ctx = Object.new
    mock_ctx.define_singleton_method(:paint) { |*args| image_double }

    anthropic_message = messages(:image_generation_tool_call).dup
    anthropic_message.assistant = assistants(:keith_claude3)

    Current.set(user: users(:keith), message: anthropic_message) do
      Toolbox::Image.stub :build_llm_context, mock_ctx do
        result = @tool.generate_an_image(image_generation_prompt_s: @prompt)

        assert_equal @prompt, result[:prompt_given]
        assert_includes result[:note_to_assistant], "image"
        assert_equal "BASE64_IMAGE_DATA_ANTHROPIC", result[:json_of_generated_image]
      end
    end
  end
end
