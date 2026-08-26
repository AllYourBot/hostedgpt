class Toolbox::Image < Toolbox

  describe :generate_an_image, <<~S
    Generate an image based on what the user asks you to generate. You will pass the user's prompt and will get back the image. If your name is Claude, you should use the generate_an_image tool.
  S

  def generate_an_image(image_generation_prompt_s:)
    backend = Current.message&.assistant&.language_model&.api_service&.ai_backend || AIBackend
    result = backend.generate_image(prompt: image_generation_prompt_s, user: Current.user)

    {
      prompt_given: image_generation_prompt_s,
      json_of_generated_image: result[:b64_json],
      note_to_assistant: "The image is already being shown on screen so reply with a nice message confirming the image has been generated, maybe re-describing it.",
      message_to_user: "Image created by tool using OpenAI model #{result[:model]}"
    }
  end
end
