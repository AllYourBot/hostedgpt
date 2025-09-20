require "test_helper"

class Toolbox::ImageTest < ActiveSupport::TestCase
  setup do
    @tool = Toolbox::Image.new
    @prompt = "A cartoon image of a cat"
  end

  test "generate_an_image calls api with expected params and returns payload" do
    response_payload = {
      "data" => {
        "b64_json" => "BASE64_IMAGE_DATA"
      }
    }

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

      OpenAI::Client.stub :new, ->(access_token:) {
        client_double
      } do
        result = @tool.generate_an_image(image_generation_prompt_s: @prompt)

        params = images_double.last_parameters
        assert_equal @prompt, params[:prompt]
        assert_equal "1024x1024", params[:size]
        assert_equal "auto", params[:quality] # dalle-e is "standard"

        assert_equal @prompt, result[:prompt_given]
        assert_includes result[:note_to_assistant], "image"
      end
    end
  end
end


