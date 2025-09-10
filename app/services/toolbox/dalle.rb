class Toolbox::Dalle < Toolbox

  describe :generate_an_image, <<~S
    Generate an image based on what the user asks you to generate. You will pass the user's prompt and will get back a URL to an image.
  S

  def generate_an_image(image_generation_prompt_s:)
    response = client.images.generate(
      parameters: {
        prompt: image_generation_prompt_s,
        model: "dall-e-3",
        size: "1024x1792",
        quality: "standard"
      }
    )

    url = response.dig("data", 0, "url")

    {
      prompt_given: image_generation_prompt_s,
      url_of_generated_image: url,
      note_to_assistant: "The image at the URL is already being shown on screen so reply with a nice message confirming the image has been generated, maybe re-describing it, but don't include the link to it."
    }
  end

  private

  def client
    OpenAI::Client.new(
      access_token: Current.message.assistant.api_service.effective_token
    )
  end
end
