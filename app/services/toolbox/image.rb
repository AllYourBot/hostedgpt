class Toolbox::Image < Toolbox

  describe :generate_an_image, <<~S
    Generate an image based on what the user asks you to generate. You will pass the user's prompt and will get back a URL to an image.
  S

  def generate_an_image(image_generation_prompt_s:)
    model = "dall-e-3" # default is dall-e-2. Others: gpt-image-1, dall-e-3.
    response = client.images.generate(
      parameters: {
        prompt: image_generation_prompt_s,
        model: model,
        size: "1024x1792",
        # n: 1,
        # size: "1024x1024",
        # quality: "standard",
        response_format: "b64_json"
      }
    )

    json =
      response.dig("data", 0, "b64_json") ||
      response.dig(:data, 0, :b64_json)
      # response.dig("data", 0, "images", 0, "data") ||
      # response.dig(:data, 0, :images, 0, :data)

    {
      prompt_given: image_generation_prompt_s,
      json_of_generated_image: json,
      note_to_assistant: "The image is already being shown on screen so reply with a nice message confirming the image has been generated, maybe re-describing it."
    }
  end

  private

  def client
    OpenAI::Client.new(
      access_token: Current.message.assistant.api_service.effective_token
    )
  end
end
