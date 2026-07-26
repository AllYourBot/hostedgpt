require "test_helper"

class Toolbox::ImageRubyLLMTest < ActiveSupport::TestCase
  include OptionsHelpers

  setup do
    stub_features(rubyllm: true)
    @tool = Toolbox::Image.new
    @prompt = "A cartoon image of a cat"
  end

  test "flag on: generate_an_image uses RubyLLM.paint" do
    image_double = RubyLLM::Image.new(data: "RUBYLLM_BASE64_DATA")

    RubyLLM::Image.stub :paint, ->(*) { image_double } do
      Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
        result = @tool.generate_an_image(image_generation_prompt_s: @prompt)

        assert_equal @prompt, result[:prompt_given]
        assert_equal "RUBYLLM_BASE64_DATA", result[:json_of_generated_image]
        assert_includes result[:note_to_assistant], "image"
      end
    end
  end

  test "flag off: existing OpenAI::Client path unchanged" do
    stub_features(rubyllm: false) do
      response_payload = { "data" => [{ "b64_json" => "LEGACY_PATH" }] }
      images_double = Class.new do
        attr_reader :last_parameters

        def initialize(response)
          @response = response
        end

        def generate(parameters:)
          @last_parameters = parameters
          @response
        end
      end.new(response_payload)

      client_double = Struct.new(:images).new(images_double)

      Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
        @tool.stub :openai_client, client_double do
          result = @tool.generate_an_image(image_generation_prompt_s: @prompt)
          assert_equal "LEGACY_PATH", result[:json_of_generated_image]
        end
      end
    end
  end
end
