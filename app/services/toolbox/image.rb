class Toolbox::Image < Toolbox

  describe :generate_an_image, <<~S
    Generate an image based on what the user asks you to generate. You will pass the user's prompt and will get back the image.
  S

  def generate_an_image(image_generation_prompt_s:)
    model = "gpt-image-1" # default is dall-e-2. Others: gpt-image-1, dall-e-3.
    response = client.images.generate(
      parameters: {
        prompt: image_generation_prompt_s,
        model: model,
        # dall-e
        # size: "1024x1792",
        # quality: "standard",
        # response_format: "b64_json"
        #
        # gpt-image-1:
        n: 1,
        size: "1024x1024",
        quality: "auto"
      }
    )

    json = response.dig("data", 0, "b64_json") ||
           response.dig(:data, 0, :b64_json)

    {
      prompt_given: image_generation_prompt_s,
      json_of_generated_image: json,
      note_to_assistant: "The image is already being shown on screen so reply with a nice message confirming the image has been generated, maybe re-describing it.",
      message_to_user: "Image created by tool"
    }
  end

  private

  def client
    # Find the user's OpenAI API service for image generation
    openai_service = Current.user.api_services.find_by(driver: :openai)

    if openai_service.nil? || openai_service.effective_token.blank?
      raise "OpenAI API key not found. Please configure your OpenAI API key in Settings > API Services to use image generation."
    end

    OpenAI::Client.new(
      access_token: openai_service.effective_token
    )
  end
end
